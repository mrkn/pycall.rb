travis_retry ()
{
    local result=0
    local count=1
    while [ $count -le 3 ]; do
        [ $result -ne 0 ] && {
            echo -e "\n${ANSI_RED}The command \"$@\" failed. Retrying, $count of 3.${ANSI_RESET}\n" 1>&2
        }
        "$@"
        result=$?
        [ $result -eq 0 ] && break
        count=$(($count + 1))
        sleep 1
    done
    [ $count -gt 3 ] && {
        echo -e "\n${ANSI_RED}The command \"$@\" failed 3 times.${ANSI_RESET}\n" 1>&2
    }
    return $result
}
