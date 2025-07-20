(** @see https://gist.github.com/Prakasaka/219fe5695beeb4d6311583e79933a009 *)

(** TODO(kinten): none of these can be nested, yet *)

let reset = "\x1B[0m"

let black  x = "\x1B[0;30m" ^ x ^ reset
let red    x = "\x1B[0;31m" ^ x ^ reset
let green  x = "\x1B[0;32m" ^ x ^ reset
let yellow x = "\x1B[0;33m" ^ x ^ reset
let blue   x = "\x1B[0;34m" ^ x ^ reset
let purple x = "\x1B[0;35m" ^ x ^ reset
let cyan   x = "\x1B[0;36m" ^ x ^ reset
let white  x = "\x1B[0;37m" ^ x ^ reset

let bold_black  x = "\x1B[1;30m" ^ x ^ reset
let bold_red    x = "\x1B[1;31m" ^ x ^ reset
let bold_green  x = "\x1B[1;32m" ^ x ^ reset
let bold_yellow x = "\x1B[1;33m" ^ x ^ reset
let bold_blue   x = "\x1B[1;34m" ^ x ^ reset
let bold_purple x = "\x1B[1;35m" ^ x ^ reset
let bold_cyan   x = "\x1B[1;36m" ^ x ^ reset
let bold_white  x = "\x1B[1;37m" ^ x ^ reset

let underline_black  x = "\x1B[4;30m" ^ x ^ reset
let underline_red    x = "\x1B[4;31m" ^ x ^ reset
let underline_green  x = "\x1B[4;32m" ^ x ^ reset
let underline_yellow x = "\x1B[4;33m" ^ x ^ reset
let underline_blue   x = "\x1B[4;34m" ^ x ^ reset
let underline_purple x = "\x1B[4;35m" ^ x ^ reset
let underline_cyan   x = "\x1B[4;36m" ^ x ^ reset
let underline_white  x = "\x1B[4;37m" ^ x ^ reset

let bg_black  x = "\x1B[40m" ^ x ^ reset
let bg_red    x = "\x1B[41m" ^ x ^ reset
let bg_green  x = "\x1B[42m" ^ x ^ reset
let bg_yellow x = "\x1B[43m" ^ x ^ reset
let bg_blue   x = "\x1B[44m" ^ x ^ reset
let bg_purple x = "\x1B[45m" ^ x ^ reset
let bg_cyan   x = "\x1B[46m" ^ x ^ reset
let bg_white  x = "\x1B[47m" ^ x ^ reset

let hi_black  x = "\x1B[0;90m" ^ x ^ reset
let hi_red    x = "\x1B[0;91m" ^ x ^ reset
let hi_green  x = "\x1B[0;92m" ^ x ^ reset
let hi_yellow x = "\x1B[0;93m" ^ x ^ reset
let hi_blue   x = "\x1B[0;94m" ^ x ^ reset
let hi_purple x = "\x1B[0;95m" ^ x ^ reset
let hi_cyan   x = "\x1B[0;96m" ^ x ^ reset
let hi_white  x = "\x1B[0;97m" ^ x ^ reset

let bold_hi_black  x = "\x1B[1;90m" ^ x ^ reset
let bold_hi_red    x = "\x1B[1;91m" ^ x ^ reset
let bold_hi_green  x = "\x1B[1;92m" ^ x ^ reset
let bold_hi_yellow x = "\x1B[1;93m" ^ x ^ reset
let bold_hi_blue   x = "\x1B[1;94m" ^ x ^ reset
let bold_hi_purple x = "\x1B[1;95m" ^ x ^ reset
let bold_hi_cyan   x = "\x1B[1;96m" ^ x ^ reset
let bold_hi_white  x = "\x1B[1;97m" ^ x ^ reset

let hi_bg_black  x = "\x1B[0;100m" ^ x ^ reset
let hi_bg_red    x = "\x1B[0;101m" ^ x ^ reset
let hi_bg_green  x = "\x1B[0;102m" ^ x ^ reset
let hi_bg_yellow x = "\x1B[0;103m" ^ x ^ reset
let hi_bg_blue   x = "\x1B[0;104m" ^ x ^ reset
let hi_bg_purple x = "\x1B[0;105m" ^ x ^ reset
let hi_bg_cyan   x = "\x1B[0;106m" ^ x ^ reset
let hi_bg_white  x = "\x1B[0;107m" ^ x ^ reset
