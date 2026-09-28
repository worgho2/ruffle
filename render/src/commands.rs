use crate::backend::ShapeHandle;
use crate::bitmap::{BitmapHandle, PixelRegion, PixelSnapping};
use crate::matrix::Matrix;
use crate::pixel_bender::PixelBenderShaderHandle;
use crate::transform::Transform;
use swf::{BlendMode, Color};

pub trait CommandHandler {
    fn render_bitmap(
        &mut self,
        bitmap: BitmapHandle,
        transform: Transform,
        smoothing: bool,
        pixel_snapping: PixelSnapping,
        region: PixelRegion,
    );
    fn render_stage3d(&mut self, bitmap: BitmapHandle, transform: Transform);
    fn render_shape(&mut self, shape: ShapeHandle, transform: Transform);
    fn render_alpha_mask(&mut self, maskee_commands: CommandList, mask_commands: CommandList);
    fn draw_rect(&mut self, color: Color, matrix: Matrix);
    fn draw_line(&mut self, color: Color, matrix: Matrix);
    fn draw_line_rect(&mut self, color: Color, matrix: Matrix);
    fn push_mask(&mut self);
    fn activate_mask(&mut self);
    fn deactivate_mask(&mut self);
    fn pop_mask(&mut self);

    fn blend(&mut self, commands: CommandList, blend_mode: RenderBlendMode);
}

/// Holds either a normal BlendMode, or the shader for BlendMode.SHADER.
///
/// We cannot store the `PixelBenderShaderHandle` directly in `ExtendedBlendMode`,
/// since we need to remember the shader even if the blend mode is changed
/// to something else (so that the shader will still be used if we switch back)
#[derive(Debug, Clone)]
pub enum RenderBlendMode {
    Builtin(BlendMode),
    Shader(PixelBenderShaderHandle),
}

#[derive(Debug, Default, Clone)]
pub struct CommandList {
    pub commands: Vec<Command>,

    /// The number of mask regions in the process of being drawn.
    /// This is used to discard drawing commands of nested maskers, which Flash does not support.
    maskers_in_progress: u32,
}

impl CommandList {
    #[inline]
    pub fn new() -> Self {
        Self::default()
    }

    #[inline]
    pub fn is_empty(&self) -> bool {
        self.commands.is_empty()
    }

    pub fn execute(self, handler: &mut impl CommandHandler) {
        for command in self.commands {
            match command {
                Command::RenderBitmap {
                    bitmap,
                    transform,
                    smoothing,
                    pixel_snapping,
                    region,
                } => handler.render_bitmap(bitmap, transform, smoothing, pixel_snapping, region),
                Command::RenderShape { shape, transform } => handler.render_shape(shape, transform),
                Command::RenderStage3D { bitmap, transform } => {
                    handler.render_stage3d(bitmap, transform)
                }
                Command::DrawRect { color, matrix } => handler.draw_rect(color, matrix),
                Command::DrawLine { color, matrix } => handler.draw_line(color, matrix),
                Command::DrawLineRect { color, matrix } => handler.draw_line_rect(color, matrix),
                Command::PushMask => handler.push_mask(),
                Command::ActivateMask => handler.activate_mask(),
                Command::DeactivateMask => handler.deactivate_mask(),
                Command::PopMask => handler.pop_mask(),
                Command::Blend(commands, blend_mode) => handler.blend(commands, blend_mode),
                Command::RenderAlphaMask {
                    maskee_commands,
                    mask_commands,
                } => handler.render_alpha_mask(maskee_commands, mask_commands),
            }
        }
    }

    pub fn drawing_mask(&self) -> bool {
        self.maskers_in_progress > 0
    }

    /// Builds the commands that paint `Color::WHITE` over every pixel this
    /// list draws, and nothing elsewhere: its coverage.
    ///
    /// `fill` is the matrix of a rectangle spanning the whole render target.
    ///
    /// Masks apply to the coverage as they apply to the content, nested blends
    /// contribute their own coverage whatever their blend mode, and the
    /// coverage of an alpha mask is that of its maskee. Strokes are left out,
    /// as the coverage is painted through masks, which never include them.
    pub fn coverage(&self, fill: Matrix) -> CommandList {
        let mut builder = CoverageBuilder {
            fill,
            commands: Vec::new(),
            run: Vec::new(),
        };
        builder.visit(self);
        builder.finish()
    }
}

/// Builds the coverage of a command list, see [`CommandList::coverage`].
///
/// Every maximal run of drawing commands becomes a mask that the fill
/// rectangle is painted through, so the fill reaches exactly the pixels the
/// run draws. Mask commands are copied as they are, so a run inside masked
/// content is painted through a nested mask.
struct CoverageBuilder {
    fill: Matrix,
    commands: Vec<Command>,
    /// The drawing commands since the last mask command, not yet painted.
    run: Vec<Command>,
}

impl CoverageBuilder {
    fn visit(&mut self, list: &CommandList) {
        // Between PushMask and ActivateMask, and between DeactivateMask and
        // PopMask, the commands define a mask rather than draw content.
        let mut defining_mask = false;
        for command in &list.commands {
            match command {
                Command::PushMask | Command::DeactivateMask => {
                    self.paint_run();
                    self.commands.push(command.clone());
                    defining_mask = true;
                }
                Command::ActivateMask | Command::PopMask => {
                    self.commands.push(command.clone());
                    defining_mask = false;
                }
                _ if defining_mask => self.commands.push(command.clone()),
                Command::Blend(commands, _) => self.visit(commands),
                Command::RenderAlphaMask {
                    maskee_commands, ..
                } => self.visit(maskee_commands),
                _ => self.run.push(command.clone()),
            }
        }
    }

    fn paint_run(&mut self) {
        if self.run.is_empty() {
            return;
        }
        self.commands.push(Command::PushMask);
        self.commands.extend(self.run.iter().cloned());
        self.commands.push(Command::ActivateMask);
        self.commands.push(Command::DrawRect {
            color: Color::WHITE,
            matrix: self.fill,
        });
        self.commands.push(Command::DeactivateMask);
        self.commands.append(&mut self.run);
        self.commands.push(Command::PopMask);
    }

    fn finish(mut self) -> CommandList {
        self.paint_run();
        CommandList {
            commands: self.commands,
            maskers_in_progress: 0,
        }
    }
}

impl CommandHandler for CommandList {
    #[inline]
    fn render_bitmap(
        &mut self,
        bitmap: BitmapHandle,
        transform: Transform,
        smoothing: bool,
        pixel_snapping: PixelSnapping,
        region: PixelRegion,
    ) {
        if self.maskers_in_progress <= 1 {
            self.commands.push(Command::RenderBitmap {
                bitmap,
                transform,
                smoothing,
                pixel_snapping,
                region,
            });
        }
    }

    #[inline]
    fn render_stage3d(&mut self, bitmap: BitmapHandle, transform: Transform) {
        if self.maskers_in_progress <= 1 {
            self.commands
                .push(Command::RenderStage3D { bitmap, transform });
        }
    }

    #[inline]
    fn render_shape(&mut self, shape: ShapeHandle, transform: Transform) {
        if self.maskers_in_progress <= 1 {
            self.commands
                .push(Command::RenderShape { shape, transform });
        }
    }

    fn render_alpha_mask(&mut self, maskee_commands: CommandList, mask_commands: CommandList) {
        if self.maskers_in_progress <= 1 {
            self.commands.push(Command::RenderAlphaMask {
                maskee_commands,
                mask_commands,
            });
        }
    }

    #[inline]
    fn draw_rect(&mut self, color: Color, matrix: Matrix) {
        if self.maskers_in_progress <= 1 {
            self.commands.push(Command::DrawRect { color, matrix });
        }
    }

    #[inline]
    fn draw_line(&mut self, color: Color, matrix: Matrix) {
        if self.maskers_in_progress <= 1 {
            self.commands.push(Command::DrawLine { color, matrix });
        }
    }

    #[inline]
    fn draw_line_rect(&mut self, color: Color, matrix: Matrix) {
        if self.maskers_in_progress <= 1 {
            self.commands.push(Command::DrawLineRect { color, matrix });
        }
    }

    #[inline]
    fn push_mask(&mut self) {
        if self.maskers_in_progress == 0 {
            self.commands.push(Command::PushMask);
        }
        self.maskers_in_progress += 1;
    }

    #[inline]
    fn activate_mask(&mut self) {
        self.maskers_in_progress -= 1;
        if self.maskers_in_progress == 0 {
            self.commands.push(Command::ActivateMask);
        }
    }

    #[inline]
    fn deactivate_mask(&mut self) {
        if self.maskers_in_progress == 0 {
            self.commands.push(Command::DeactivateMask);
        }
        self.maskers_in_progress += 1;
    }

    #[inline]
    fn pop_mask(&mut self) {
        self.maskers_in_progress -= 1;
        if self.maskers_in_progress == 0 {
            self.commands.push(Command::PopMask);
        }
    }

    #[inline]
    fn blend(&mut self, commands: CommandList, blend_mode: RenderBlendMode) {
        if self.maskers_in_progress <= 1 {
            self.commands.push(Command::Blend(commands, blend_mode));
        }
    }
}

#[derive(Debug, Clone)]
pub enum Command {
    RenderBitmap {
        bitmap: BitmapHandle,
        transform: Transform,
        smoothing: bool,
        pixel_snapping: PixelSnapping,
        region: PixelRegion,
    },
    RenderStage3D {
        bitmap: BitmapHandle,
        transform: Transform,
    },
    RenderShape {
        shape: ShapeHandle,
        transform: Transform,
    },
    RenderAlphaMask {
        maskee_commands: CommandList,
        mask_commands: CommandList,
    },
    DrawRect {
        color: Color,
        matrix: Matrix,
    },
    DrawLine {
        color: Color,
        matrix: Matrix,
    },
    DrawLineRect {
        color: Color,
        matrix: Matrix,
    },
    PushMask,
    ActivateMask,
    DeactivateMask,
    PopMask,
    Blend(CommandList, RenderBlendMode),
}
