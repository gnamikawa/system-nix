{ ... }:
{
  name = "hello-world";

  nodes.machine =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.hello ];

      # Avoid pulling in a full desktop/login stack for a smoke test
      services.getty.autologinUser = "root";
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Run the actual binary and assert on its output
    output = machine.succeed("hello").strip()
    assert output == "Hello, world!", f"unexpected output: {output!r}"

    print("hello-world test passed")
  '';
}
