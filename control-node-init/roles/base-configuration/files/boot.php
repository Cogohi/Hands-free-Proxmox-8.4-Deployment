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
  $script_template = file_get_contents('/var/www/data/boot.txt.tmpl', false);
  $script = str_replace("{HTTP_HOST}", $_SERVER['HTTP_HOST'], $script_template);

  echo $script;
}

