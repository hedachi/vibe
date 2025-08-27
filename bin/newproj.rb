#!/usr/bin/env ruby
# usage: newproj.rb "最初の指示"
require 'fileutils'
require 'json'

prompt = ARGV.join(" ").strip
abort("prompt required") if prompt.empty?

base = File.expand_path("~")  # プロジェクト保存先
slug = Time.now.strftime("%Y%m%d-%H%M%S") + "-" + prompt.gsub(/[^\p{Alnum}\-_. ]/u, '').strip.gsub(/\s+/, '-')[0,60]
dir  = File.join(base, slug)
FileUtils.mkdir_p(dir)

# READMEに指示を保存（任意）
File.write(File.join(dir, "README.md"), "# #{prompt}\n\n初回プロンプト: #{prompt}\n")

# VS Codeの自動タスク設定
tasks_dir = File.join(dir, ".vscode")
FileUtils.mkdir_p(tasks_dir)

# Claude Codeコマンド構築
cmd = %(claude "#{prompt.gsub('"','\"')}" --permission-mode plan)
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

# VS Codeを新規ウィンドウで開く
# codeコマンドが使えない場合は直接アプリを起動
if system("which code > /dev/null 2>&1")
  exec(%Q{code -n "#{dir}"})
else
  exec(%Q{open -n -a "Visual Studio Code" --args "#{dir}"})
end