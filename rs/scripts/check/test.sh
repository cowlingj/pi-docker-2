help() {
  echo "$0 $@ - Run all tests"
}

description() {
  echo "Run all tests"
}

run() {
  rs_info "running tests"
  local EXPECTED_RESULTS="./scripts/check/expected-results"
  local SUCCESS=0
  diff \
    <(RS_SCRIPTS_BASE_DIR='./test' ./app/rs.sh --list) \
    <(cat "$EXPECTED_RESULTS/list-root.txt") \
    && rs_success "list-root" || { rs_error "list-root"; SUCCESS=1; }
  diff \
    <(RS_SCRIPTS_BASE_DIR='./test' ./app/rs.sh --list test) \
    <(cat "$EXPECTED_RESULTS/list-sub-dir1.txt") \
    && rs_success "list-sub-dir1" || { rs_error "list-sub-dir1"; SUCCESS=1; }
  diff \
    <(RS_SCRIPTS_BASE_DIR='./test' ./app/rs.sh --list test test2) \
    <(cat "$EXPECTED_RESULTS/list-sub-dir2.txt") \
    && rs_success "list-sub-dir2" || { rs_error "list-sub-dir2"; SUCCESS=1; }
  diff \
    <(RS_SCRIPTS_BASE_DIR='./test' ./app/rs.sh --list test2 sub 2>&1) \
    <(echo -e "$(cat "$EXPECTED_RESULTS/list-missing.txt")") \
    && rs_success "list-missing" || { rs_error "list-missing"; SUCCESS=1; }
  diff \
    <(RS_SCRIPTS_BASE_DIR='./test' ./app/rs.sh --tree) \
    <(cat "$EXPECTED_RESULTS/tree-root.txt") \
    && rs_success "tree-root" || { rs_error "tree-root"; SUCCESS=1; }
  diff \
    <(RS_SCRIPTS_BASE_DIR='./test' ./app/rs.sh --tree test) \
    <(cat "$EXPECTED_RESULTS/tree-sub-dir.txt") \
    && rs_success "tree-sub-dir" || { rs_error "tree-sub-dir"; SUCCESS=1; }
  
  echo ""
  
  if [ $SUCCESS -eq 0 ]; then
    rs_success "all tests passed"
  else
    rs_error "some tests failed"
  fi
  return $SUCCESS
}