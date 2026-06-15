-- autocmds — 段階的に追記していく。

-- IME 自動オフ: insert mode を抜けた瞬間に fcitx5 を無効化する。
-- 日本語入力したまま Esc → normal/command mode で日本語が誤入力される事故を防ぐ (WSL 時代と同じ運用)。
-- InsertLeave なので Esc 以外の抜け方 (<C-c> / <C-[> 等) も全部カバーする。
-- vim.system で非同期呼び出し (fork でカクつかない)。fcitx5-remote が無い環境では no-op (可搬性)。
if vim.fn.executable("fcitx5-remote") == 1 then
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = vim.api.nvim_create_augroup("ime_off_on_insertleave", { clear = true }),
    callback = function()
      vim.system({ "fcitx5-remote", "-c" }) -- -c = IME を無効化 (deactivate)
    end,
    desc = "Disable fcitx5 IME when leaving insert mode",
  })
end
