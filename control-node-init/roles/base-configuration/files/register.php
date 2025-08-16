<?php
$method = $_SERVER['REQUEST_METHOD'];
$request = explode("/", substr(@$_SERVER['PATH_INFO'], 1));

switch ($method) {
  case 'PUT':
    // put_handler($request);
    handle_error($request);
    break;
  case 'POST':
    post_handler($request);
    break;
  case 'GET':
    get_handler($request);
    break;
  default:
    handle_error($request);
    break;
}

function get_prefix($address, $netmask) {
  $octets_a = explode(".", $address);
  $octets_m = explode(".", $netmask);
  $prefix = "";
  for($i=0; $i<4; $i++) {
    if($octets_m[$i] == "0") {
      break;
    }
    $prefix = $prefix . $octets_a[$i] . ".";
  }
  return $prefix;
}

function get_server_prefix() {
  $s = $_SERVER['SERVER_ADDR'];
  $n = net_get_interfaces();

  foreach($n as $name => $info) {
    foreach($info["unicast"] as $b) {
      if($b["family"] == 2) {
        if($b["address"] == $_SERVER['SERVER_ADDR']) {
          return get_prefix($b["address"],$b["netmask"]);
        }
      }
    }
  }

  return "<not found>";
}

function full_path()
{
    $s = &$_SERVER;
    $ssl = (!empty($s['HTTPS']) && $s['HTTPS'] == 'on') ? true:false;
    $sp = strtolower($s['SERVER_PROTOCOL']);
    $protocol = substr($sp, 0, strpos($sp, '/')) . (($ssl) ? 's' : '');
    $port = $s['SERVER_PORT'];
    $port = ((!$ssl && $port=='80') || ($ssl && $port=='443')) ? '' : ':'.$port;
    $host = isset($s['HTTP_X_FORWARDED_HOST']) ? $s['HTTP_X_FORWARDED_HOST'] : (isset($s['HTTP_HOST']) ? $s['HTTP_HOST'] : null);
    $host = isset($host) ? $host : $s['SERVER_NAME'] . $port;
    $uri = $protocol . '://' . $host . $s['REQUEST_URI'];
    $segments = explode('?', $uri, 2);
    $url = $segments[0];
    return $url;
}

function handle_error($request) {
  http_response_code(400);
}

function post_handler($request) {
  $request = file_get_contents('php://input');
  $req_dump = print_r( $request, true );

  echo "Received: " . $req_dump . "\n";
}

function get_handler($request) {
  $url = full_path();
  $script_template = file_get_contents('/var/www/data/register.sh.tmpl', false);
  $script = str_replace("{NET_PREFIX}", get_server_prefix(), $script_template);
  $script = str_replace("{INSTALL_TYPES}", "1 proxmox 2 opnsense 3 deb12nas", $script);
  $script = str_replace("{REGISTRATION_HOOK}", $url, $script);

  echo $script;
}
