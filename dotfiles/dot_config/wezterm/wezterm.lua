-- wezterm.lua — chezmoi managed
-- 役割: 「薄い高品質端末」。描画(フォント/テーマ/GPU)・端末ローカル操作のみ担当。
-- 多重化(pane/window/session)は tmux に委譲し、ここでは tab bar も分割キーも持たない
--   (tmux の prefix C-a 操作とキー衝突させないため)。
-- Lua は全 OS 同一で可搬。OS 差は wezterm.target_triple で実行時分岐できる(現状は不要)。

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 既定値。Ctrl+Shift+O/I で透過率、Ctrl +/-/0 でフォントサイズを実行時調整し、
-- いずれも state ファイルに永続化して次回起動で復元する(旧 dotfiles の透過率移植を一般化)。
local DEFAULT_OPACITY = 1.0
local DEFAULT_FONT_SIZE = 12.0  -- 旧 dotfiles は 14.0。既定を変えたければこの値を変更

-- ランタイム状態の永続化ヘルパ (透過率・フォントサイズ共通)。
-- config_dir 配下に <name>.state として保存。config_dir は全OSで存在し mkdir 不要で可搬。
-- .lua ではないので auto-reload は誘発しない。ランタイム書込のため chezmoi 管理外(.chezmoiignore)。
local function load_state(name, default)
  local f = io.open(wezterm.config_dir .. "/" .. name .. ".state", "r")
  if not f then return default end
  local v = tonumber((f:read("*l") or ""))
  f:close()
  return v or default
end

local function save_state(name, v)
  local f = io.open(wezterm.config_dir .. "/" .. name .. ".state", "w")
  if f then
    f:write(tostring(v))
    f:close()
  end
end

-- ---------- Appearance (tmux/starship と配色統一: tokyonight storm) ----------
--config.color_scheme = "Tokyo Night Storm"
config.color_scheme = "Wez"
config.font = wezterm.font_with_fallback({
  "HackGen Console NF",      -- 主フォント (旧 dotfiles と同じ。CJK + Nerd Font アイコン)。要 hackgen-nf-font
  "JetBrainsMono Nerd Font", -- フォールバック
})
config.font_size = load_state("fontsize", DEFAULT_FONT_SIZE)  -- 前回の Ctrl +/-/0 値を復元
config.line_height = 1.0
config.adjust_window_size_when_changing_font_size = false

-- ---------- Window ----------
-- TITLE|RESIZE: KDE の通常フレーム(タイトルバー + ドラッグ可能な端)を付け、他アプリ同様に
-- ウィンドウ端マウスドラッグでリサイズできるようにする。タイトルバー不要なら "RESIZE" に戻す。
config.window_decorations = "TITLE | RESIZE"
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = load_state("opacity", DEFAULT_OPACITY)  -- 前回の Ctrl+Shift+O/I 値を復元

-- ---------- 多重化は tmux に委譲 ----------
-- tmux が window 一覧を status bar に表示するので wezterm のタブバーは非表示(冗長回避)。
config.enable_tab_bar = false

-- ---------- Keybindings (端末ローカル操作のみ。多重化系は定義せず tmux へ) ----------
-- 注: 変更のフィードバックは toast_notification を使わない。KDE のデスクトップ通知として
--     飛び、連打でバルーンが大量に積み上がるため。変化は画面で視認できるので通知不要。
config.keys = {
  -- フォントサイズ (端末ローカル操作)。set_config_overrides で変更し state に永続化。
  -- フォールバックは load_state(保存値)。固定既定値だと再起動後の初回押下で値が飛ぶため。
  {
    key = "=",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, _pane)
      local o = window:get_config_overrides() or {}
      o.font_size = (o.font_size or load_state("fontsize", DEFAULT_FONT_SIZE)) + 1.0
      window:set_config_overrides(o)
      save_state("fontsize", o.font_size)
    end),
  },
  {
    key = "-",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, _pane)
      local o = window:get_config_overrides() or {}
      o.font_size = math.max((o.font_size or load_state("fontsize", DEFAULT_FONT_SIZE)) - 1.0, 6.0)
      window:set_config_overrides(o)
      save_state("fontsize", o.font_size)
    end),
  },
  {
    key = "0",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, _pane)
      local o = window:get_config_overrides() or {}
      o.font_size = DEFAULT_FONT_SIZE
      window:set_config_overrides(o)
      save_state("fontsize", DEFAULT_FONT_SIZE)
    end),
  },

  -- quick-select (画面上の URL/パス/ハッシュ等を素早く選択コピー。端末ローカル機能)
  { key = "Space", mods = "CTRL|SHIFT", action = wezterm.action.QuickSelect },

  -- クリップボード copy/paste を明示バインド。
  -- Ctrl+C は SIGINT・Ctrl+V はリテラル入力で潰せないため Ctrl+Shift に置くのが端末の慣習。
  -- copy は CLIPBOARD と PRIMARY の両方へ入れて「マウス選択は PRIMARY だけ」問題を回避。
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },

  -- 背景透過率の実行時調整 (旧 dotfiles から移植)。O=濃く(+5%) / I=薄く(-5%)。
  -- フォールバックは load_state(保存値)。再起動後の初回押下で値が飛ばないようにするため。
  {
    key = "o",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, _pane)
      local o = window:get_config_overrides() or {}
      o.window_background_opacity = math.min((o.window_background_opacity or load_state("opacity", DEFAULT_OPACITY)) + 0.05, 1.0)
      window:set_config_overrides(o)
      save_state("opacity", o.window_background_opacity)
    end),
  },
  {
    key = "i",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, _pane)
      local o = window:get_config_overrides() or {}
      o.window_background_opacity = math.max((o.window_background_opacity or load_state("opacity", DEFAULT_OPACITY)) - 0.05, 0.1)
      window:set_config_overrides(o)
      save_state("opacity", o.window_background_opacity)
    end),
  },
}

-- ---------- Mouse ----------
-- マウス選択の確定時に CLIPBOARD にも入れる(既定は PRIMARY のみ)。
-- これで「マウス選択 → Ctrl+Shift+V で貼れない」食い違いを解消。
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  -- スマート右クリック (Windows Terminal / PuTTY 流。wezterm に GUI メニューは無いためこれで代替):
  --   選択あり → コピー(CLIPBOARD+PRIMARY)して選択解除 / 選択なし → カーソル位置にペースト。
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local sel = window:get_selection_text_for_pane(pane)
      if sel and sel ~= "" then
        window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(wezterm.action.ClearSelection, pane)
      else
        window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
      end
    end),
  },
}
-- ペイン分割/タブ移動キーは敢えて未定義 → tmux の prefix 操作に一本化。

-- ---------- Hyperlinks (URL クリック) ----------
config.hyperlink_rules = wezterm.default_hyperlink_rules()

return config
