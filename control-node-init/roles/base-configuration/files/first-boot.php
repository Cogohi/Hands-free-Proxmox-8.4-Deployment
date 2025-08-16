<?php
$method = $_SERVER['REQUEST_METHOD'];
$request = explode("/", substr(@$_SERVER['PATH_INFO'], 1));

switch ($method) {
  case 'PUT':
    handle_error($request);
    break;
  case 'POST':
    handle_error($request);
    break;
  case 'GET':
    get_handler($request);
    break;
  default:
    handle_error($request);
    break;
}

function handle_error($request) {
  http_response_code(400);
}

function get_handler($request) {
  // TODO: read ~/.ssh/authorized_keys* and ~/.ssh/id_*.pub into $authorized_keys
  $script_template = file_get_contents('/var/www/data/first-boot.sh.tmpl', false);
  $script = str_replace("{AUTHORIZED_KEYS}", $authorized_keys, $script_template);

  echo $script;
}

