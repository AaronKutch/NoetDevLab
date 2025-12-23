let 
  username = "Noet";
in {
  inherit username;
  homeDirectory = "/home/${username}";
}