describe 'database' do
  before do
    `rm -rf test.db`
  end

  def run_script(commands)
    raw_output = nil
    IO.popen("./tiny-sql test.db", "r+") do |pipe|
      commands.each do |command|
        pipe.puts command
      end

      pipe.close_write

      # Read entire output
      raw_output = pipe.gets(nil)
    end
    raw_output.split("\n")
  end

  it 'inserts and retrieves a row' do
    result = run_script([
      "insert 1 user1 person1@example.com",
      "select",
      ".exit",
    ])
    expect(result).to match_array([
      "tiny-sql> Executed.",
      "tiny-sql> (1, user1, person1@example.com)",
      "Executed.",
      "tiny-sql> ",
    ])
  end

  it 'print error message when table is full' do
    script = (1..1501) .map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".exit"
    result = run_script(script)
    expect(result[-2]).to eq("tiny-sql> Error: table full.")
  end

  it 'allows inserting strings that are the maximum length' do
    log_username = "a"*33
    log_email = "a"*256
    script = [
      "insert 1 #{log_username} #{log_email}",
      "select",
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "tiny-sql> Error: string is too long!",
      "tiny-sql> Executed.",
      "tiny-sql> ",
    ])
  end

  it 'prints an error message if id is negative' do
    script = [
      "insert -1 ahmadrosid some@mail.com",
      "select",
      ".exit"
    ]

    result = run_script(script)
    expect(result).to match_array([
      "tiny-sql> ID must be a positive",
      "tiny-sql> Executed.",
      "tiny-sql> "
    ])
  end

  it 'keeps data after closing connection' do
    result1 = run_script([
      "insert 1 ahmadrosid some@mail.com",
      ".exit"
    ])
    expect(result1).to match_array([
      "tiny-sql> Executed.",
      "tiny-sql> "
    ])
    result2 = run_script([
      "select",
      ".exit"
    ])
    expect(result2).to match_array([
      "tiny-sql> (1, ahmadrosid, some@mail.com)",
      "Executed.",
      "tiny-sql> "
    ])
  end
end

