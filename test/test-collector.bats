setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
}

@test "shows an error if you don't pipe in a JUnit" {
  run ./test-collector
  assert_output --partial 'No JUnit stream found on STDIN'
}