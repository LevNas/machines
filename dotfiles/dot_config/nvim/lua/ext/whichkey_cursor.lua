-- ============================================================================
-- 独自拡張: which-key のポップアップをカーソル付近に表示する (mini.clue 風)
-- ============================================================================
-- which-key v3 はポップアップを relative="editor" に強制し (win.lua override)、
-- かつ窓オープン時に eventignore="all"/noautocmd=true で autocmd を発火させない。
-- そのため「公式 opts」でも「後追い autocmd」でもカーソル相対配置はできない。
--
-- 唯一成立する手段として which-key.win の show メソッドを "追記ラップ" し、
-- which-key 本来の描画が終わった後に nvim_win_set_config で窓をカーソル相対へ動かす。
--
-- 【フェイルセーフ設計 — 拡張が壊れても which-key は素で動く】
--   1. 本体 orig_show を必ず先に実行する (戻り値もそのまま返す)。再配置は "後付け"。
--   2. capability check: 期待する内部 API (which-key.win / show 関数) が無ければ
--      ラップせず即 return → 素の which-key に委ねる (将来の API 変更で自動降格)。
--   3. 再配置は pcall で隔離 + M.enabled フラグ。実行時エラーや無効化で素の位置に降格。
--   4. __cursor_ext フラグで二重ラップを防止 (再 setup されても1回だけ適用)。
-- この拡張ファイルが丸ごと欠落/エラーでも、呼び出し側 (plugins/which-key.lua) が
-- pcall で包んでいるため which-key.setup 自体は完走する。
-- ============================================================================

local M = {}

-- 拡張の ON/OFF。問題が出たら false にするだけで「素の which-key (画面端)」に戻せる。
M.enabled = true

-- which-key の1つの浮動窓 (win id) をカーソル相対位置へ再配置する。
-- 失敗しても呼び出し側が pcall するため、その場合は which-key 既定位置のまま。
local function reposition(win)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local height = vim.api.nvim_win_get_height(win)
  local lines = vim.o.lines
  local srow = vim.fn.screenrow() -- カーソルの絶対画面行 (1-based)
  -- カーソル下に窓 + 余白(2) が収まるなら下側(NW)、収まらなければ上側(SW)へ。
  local below = (srow + height + 2) <= lines
  vim.api.nvim_win_set_config(win, {
    relative = "cursor",
    row = below and 1 or 0,   -- 下: カーソルの1行下 / 上: カーソル行で底辺合わせ
    col = 0,
    anchor = below and "NW" or "SW",
  })
end

-- which-key.win.show を追記ラップする。冪等 (何度呼んでも1回だけラップ)。
function M.setup()
  if not M.enabled then
    return
  end

  local ok, Win = pcall(require, "which-key.win")
  -- capability check: 内部 API が期待通りでなければ拡張しない (= 素の which-key)。
  if not ok or type(Win) ~= "table" or type(Win.show) ~= "function" then
    return
  end
  if Win.__cursor_ext then
    return -- 既にラップ済み
  end

  local orig_show = Win.show
  Win.show = function(self, opts)
    -- which-key 本来の show を必ず先に完走させる (本体は拡張に一切依存しない)。
    local ret = orig_show(self, opts)
    -- 描画後に窓だけカーソル相対へ動かす。失敗は握りつぶし素の位置に降格。
    if M.enabled then
      pcall(reposition, self.win)
    end
    return ret
  end
  Win.__cursor_ext = true
end

return M
