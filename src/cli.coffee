fs           = require "fs"
path         = require "path"
clc          = require "cli-color"
parse_config = (require "./config").parse
{deploy}     = require "./deploy"

# Logging facilities
log_err  = (t) -> console.log (clc.red t)
log_info = (t) -> console.log (clc.yellow t)

exports.run = (args) ->
  switch args[0]
    when "help" then print_usage()
    when "init" then init_config()
    when "deploy" then do_deploy args[1]
    when "completion=bash" then print_completion('bash')
    when "completion=zsh" then print_completion('zsh')
    else print_usage()

print_completion = (name)->
  code = 0
  filepath = path.join __dirname, '../completion', name
  console.log String fs.readFileSync filepath
  process.exit code

print_usage = ->
  commands =
    deploy: "Deploy using the given config file or $MINJA_CONFIG or deploy.json"
    init  : "Write an example config file"
    help  : "That's me"

  console.log "Usage: minja [command] [config file]\n"
  console.log (clc.yellow "Commands:")
  for cmd, desc of commands
    console.log "#{cmd}:\t#{desc}"

do_deploy = (config_path) ->
  # Which config file do we use?
  config_path ?= process.env["MINJA_CONFIG"] ? "deploy.json"
  if not fs.existsSync config_path
    log_err "Config file '#{config_path}' not found"
    process.exit 1

  # Parse config
  log_info "Using config file '#{config_path}'"
  try
    config = parse_config config_path
  catch e
    log_err "Error parsing config file: #{e}"
    process.exit 1

  # Deploy!
  deploy config

init_config = ->
  example_conf =
    server: "user@host"
    port: 22
    server_dir: "/path/to/dir/on/server"
    repo: "git@github.com:user/repo.git"
    prj_git_relative_dir: ""
    branch: "master"
    force_regenerate_git_dir: false
    shared_dirs: ["node_modules", "db"]
    prerun: [
      "npm install",
      "npm test"
    ]
    run_cmd: "npm start"

  # Ensure deploy script doesn't exist
  config_path = "deploy.json"
  if fs.existsSync config_path
    log_err "File #{config_path} already exists. I better dont't touch it!"
    process.exit 1

  # Write config
  f = fs.createWriteStream config_path
  f.end (JSON.stringify example_conf, null, 2)
