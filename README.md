# InvokerLib v1.1
Three changes made:

Active = true on LogoSection — This was the root cause of dragging being broken. Fully transparent frames don't capture mouse events unless Active is explicitly set to true. Without it, InputBegan never fired on the handle, so drag never started.
Direct Position set instead of Tween in the drag loop — The Tween with 0.05s was adding a tiny animation delay on every mouse move event, making the window feel laggy and jittery. Direct assignment makes it perfectly snappy.
RightControl → RightShift — Changed the default toggle keybind as requested. You can still override it per-window with ToggleKey = Enum.KeyCode.Whatever in your CreateWindow config.

You can access the wiki for lib right there: https://invokerlib.gitbook.io/invokerlib-docs
