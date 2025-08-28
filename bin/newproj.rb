#!/usr/bin/env ruby
# usage: newproj.rb "最初の指示"
require 'fileutils'
require 'json'

prompt = ARGV.join(" ").strip
abort("prompt required") if prompt.empty?

# ランダムカラー生成（見やすい色範囲で生成）
def generate_random_color
  # HSLで色相をランダムに、彩度と明度は見やすい範囲に設定
  h = rand(360)
  s = 40 + rand(40)  # 40-80%の彩度
  l = 35 + rand(25)  # 35-60%の明度
  
  # HSLからRGBへ変換
  c = (1 - (2 * l / 100.0 - 1).abs) * (s / 100.0)
  x = c * (1 - ((h / 60.0) % 2 - 1).abs)
  m = l / 100.0 - c / 2.0
  
  r, g, b = case (h / 60).floor
  when 0 then [c, x, 0]
  when 1 then [x, c, 0]
  when 2 then [0, c, x]
  when 3 then [0, x, c]
  when 4 then [x, 0, c]
  when 5 then [c, 0, x]
  else [0, 0, 0]
  end
  
  # RGBを16進数に変換
  "#%02X%02X%02X" % [(r + m) * 255, (g + m) * 255, (b + m) * 255]
end

# カラーを暗くする
def darken_color(hex, amount = 0.2)
  rgb = hex.scan(/[A-F0-9]{2}/i).map { |x| x.hex }
  rgb = rgb.map { |c| [(c * (1 - amount)).to_i, 0].max }
  "#%02X%02X%02X" % rgb
end

# カラーを明るくする
def lighten_color(hex, amount = 0.2)
  rgb = hex.scan(/[A-F0-9]{2}/i).map { |x| x.hex }
  rgb = rgb.map { |c| [(c + (255 - c) * amount).to_i, 255].min }
  "#%02X%02X%02X" % rgb
end

# ベースカラーを生成
base_color = generate_random_color

base = File.expand_path("~")  # プロジェクト保存先
slug = Time.now.strftime("%Y%m%d-%H%M%S") + "-" + prompt.gsub(/[^\p{Alnum}\-_. ]/u, '').strip.gsub(/\s+/, '-')[0,60]
dir  = File.join(base, slug)
FileUtils.mkdir_p(dir)

# 実装計画.mdに指示を保存
File.write(File.join(dir, "実装計画.md"), <<~MD)
  # 実装計画

  ## 初回プロンプト
  #{prompt}

  ## タスク
  以下の要件を実装してください：
  - #{prompt}

  ## 実装方針
  上記の要件を満たすために、適切な実装を行ってください。
MD

# VS Codeの自動タスク設定
tasks_dir = File.join(dir, ".vscode")
FileUtils.mkdir_p(tasks_dir)

# Claude Codeコマンド構築
cmd = %(claude "実装計画.mdを読んで、そこに記載されている要件を実装してください。")
# 必要に応じてツール許可を追加
# cmd += %( --allowedTools "Bash" "Read" "Edit" "Write")

tasks = {
  "version" => "2.0.0",
  "tasks" => [
    {
      "label" => "Claude: kickoff",
      "type" => "shell",
      "command" => cmd,
      "runOptions" => {"runOn" => "folderOpen"},
      "problemMatcher" => [],
      "presentation" => {
        "echo" => true,
        "reveal" => "always",
        "focus" => true,
        "panel" => "new",
        "showReuseMessage" => false,
        "clear" => false
      }
    }
  ]
}

File.write(File.join(tasks_dir, "tasks.json"), JSON.pretty_generate(tasks))

# VSCodeカラー設定を作成（他のプロジェクトと識別しやすくするため）
accent_color = generate_random_color  # バッジ用のアクセントカラー
settings = {
  "workbench.colorCustomizations" => {
    "titleBar.activeBackground" => base_color,
    "titleBar.activeForeground" => "#FFFFFF",
    "titleBar.inactiveBackground" => darken_color(base_color, 0.3),
    "titleBar.inactiveForeground" => "#CCCCCC",
    "statusBar.background" => base_color,
    "statusBar.foreground" => "#FFFFFF",
    "statusBar.debuggingBackground" => "#A74C4C",
    "statusBar.debuggingForeground" => "#FFFFFF",
    "statusBarItem.hoverBackground" => lighten_color(base_color, 0.15),
    "activityBar.background" => darken_color(base_color, 0.4),
    "activityBar.foreground" => "#FFFFFF",
    "activityBar.inactiveForeground" => "#AAAAAA",
    "activityBarBadge.background" => accent_color,
    "activityBarBadge.foreground" => "#FFFFFF"
  }
}

File.write(File.join(tasks_dir, "settings.json"), JSON.pretty_generate(settings))

# VS Codeを新規ウィンドウで開く
# codeコマンドが使えない場合は直接アプリを起動
if system("which code > /dev/null 2>&1")
  exec(%Q{code -n "#{dir}"})
else
  exec(%Q{open -n -a "Visual Studio Code" --args "#{dir}"})
end