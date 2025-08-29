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

# VS Codeの自動タスク設定
tasks_dir = File.join(dir, ".vscode")
FileUtils.mkdir_p(tasks_dir)

# 初回実行チェック用のスクリプト
check_and_run_cmd = <<~SCRIPT
if [ ! -f ".vscode/.kickoff_done" ]; then
  claude "「#{prompt.gsub('"','\"')}」という要件について、詳細な実装計画を立てて実装計画.mdファイルに書いてください。その後、その計画に従って実装してください。"
  touch .vscode/.kickoff_done
else
  claude
fi
SCRIPT

tasks = {
  "version" => "2.0.0",
  "tasks" => [
    {
      "label" => "Claude: kickoff (first time only)",
      "type" => "shell",
      "command" => "bash",
      "args" => ["-c", check_and_run_cmd.strip],
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
  system(%Q{code -n "#{dir}"})
else
  system(%Q{open -n -a "Visual Studio Code" --args "#{dir}"})
end

# VSCodeの色をランダムに設定
system("vscrand")