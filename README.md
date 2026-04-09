# InvokerLib v1.1
Three changes made:

- [x] `Active = true` on `LogoSection` — This was the root cause of dragging being broken. Fully transparent frames don't capture mouse events unless Active is explicitly set to `true`. Without it, `InputBegan` never fired on the handle, so drag never started.

- [x] Direct `Position` set instead of `Tween` in the drag loop — The `Tween` with `0.05s` was adding a tiny animation delay on every mouse move event, making the window feel laggy and jittery. Direct assignment makes it perfectly snappy.

- [x] `RightControl` → `RightShift` — Changed the default toggle keybind. You can still override it per-window with `ToggleKey = Enum.KeyCode.Whatever` in your `CreateWindow` config.

You can access the wiki for lib right there: https://invokerlib.gitbook.io/invokerlib-docs

You're vibecoding? No problem, from now on, you can use AI Instructions for my library!
https://github.com/meepodota/invokerlib/blob/main/invokerlib-ai-instructions.txt

![preview](https://cdn.discordapp.com/attachments/1491036329637580920/1491792154241142917/image.png?ex=69d8fb35&is=69d7a9b5&hm=45e9c496f5aeedcb7b59e0508e374515ebd80793d24a4a255f7c2bf942a6e4b5&)
