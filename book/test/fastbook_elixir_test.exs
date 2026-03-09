defmodule FastbookElixirTest do
  use ExUnit.Case

  test "extract_tar_from_binary handles valid tar" do
    # Create a tar archive via a temp file, then read the binary
    tmp_dir = System.tmp_dir!()
    tar_path = Path.join(tmp_dir, "test_fastbook.tar.gz")
    file_path = Path.join(tmp_dir, "hello.txt")

    File.write!(file_path, "world")
    :erl_tar.create(~c"#{tar_path}", [{~c"hello.txt", ~c"#{file_path}"}], [:compressed])

    tar_binary = File.read!(tar_path)
    result = FastbookElixir.extract_tar_from_binary(tar_binary)
    assert result == %{"hello.txt" => "world"}

    File.rm(tar_path)
    File.rm(file_path)
  end
end
