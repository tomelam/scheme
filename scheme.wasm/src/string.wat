;; strings are represented as an i32 length followed by length bytes of utf-8 encoded string

(func $str-from-32 (param $len i32) (param $data i32) (result i32)
  (local $ptr i32)  ;; the return value and pointer to the string

  ;; if (len > 4) {
  (if (i32.gt_u (local.get $len) (i32.const 4))
  ;;   trap
    (then unreachable)
  )
  ;; }

  ;; ptr = malloc(8)
  (local.set $ptr (call $malloc (i32.const 8)))

  ;; *ptr = len
  (i32.store (local.get $ptr) (local.get $len))
  ;; *(ptr + 4) = data
  (i32.store offset=4 (local.get $ptr) (local.get $data))

  ;; return ptr
  (return (local.get $ptr))
)

(func $str-from-64 (param $len i32) (param $data i64) (result i32)
  (local $ptr i32)  ;; the return value and pointer to the string

  ;; if (len > 8) {
  (if (i32.gt_u (local.get $len) (i32.const 8))
  ;;   trap
    (then unreachable)
  )
  ;; }

  ;; ptr = malloc(12)
  (local.set $ptr (call $malloc (i32.const 12)))

  ;; *ptr = len
  (i32.store (local.get $ptr) (local.get $len))
  ;; *(ptr + 4) = data
  (i64.store offset=4 (local.get $ptr) (local.get $data))

  ;; return ptr
  (return (local.get $ptr))
)

(func $str-from-128 (param $len i32) (param $data1 i64) (param $data2 i64) (result i32)
  (local $ptr i32)  ;; the return value and pointer to the string

  ;; if (len > 16) {
  (if (i32.gt_u (local.get $len) (i32.const 16))
  ;;   trap
    (then unreachable)
  )
  ;; }

  ;; if (len <= 8) {
  (if (i32.le_s (local.get $len) (i32.const 8))
    (then
  ;;    return str-from-64(len, data1)
      (return (call $str-from-64 (local.get $len) (local.get $data1)))
  ;; }
    )
  )

  ;; ptr = malloc(20)
  (local.set $ptr (call $malloc (i32.const 20)))

  ;; *ptr = len
  (i32.store (local.get $ptr) (local.get $len))
  ;; *(ptr + 4) = data1
  (i64.store offset=4 (local.get $ptr) (local.get $data1))
  ;; *(ptr + 12) = data2
  (i64.store offset=12 (local.get $ptr) (local.get $data2))

  ;; return ptr
  (return (local.get $ptr))
)

(func $str-from-192 (param $len i32) (param $data1 i64) (param $data2 i64) (param $data3 i64) (result i32)
  (local $ptr i32)  ;; the return value and pointer to the string

  ;; if (len > 24) {
  (if (i32.gt_u (local.get $len) (i32.const 24))
    ;; trap
    (then unreachable)
  )
  ;; } else if (len <= 8) {
  (if (i32.le_s (local.get $len) (i32.const 8))
    (then
      ;; return str-from-64(len, data1)
      (return (call $str-from-64 (local.get $len) (local.get $data1)))
    )
  )
  ;; } else if (len <= 16) {
  (if (i32.le_s (local.get $len) (i32.const 16))
    (then
      ;; return str-from-128(len, data1, data2)
      (return (call $str-from-128 (local.get $len) (local.get $data1) (local.get $data2)))
      ;; }
    )
  )

  ;; ptr = malloc(28)
  (local.set $ptr (call $malloc (i32.const 28)))

  ;; *ptr = len
  (i32.store (local.get $ptr) (local.get $len))
  ;; *(ptr + 4) = data1
  (i64.store offset=4 (local.get $ptr) (local.get $data1))
  ;; *(ptr + 12) = data2
  (i64.store offset=12 (local.get $ptr) (local.get $data2))
  ;; *(ptr + 20) = data3
  (i64.store offset=20 (local.get $ptr) (local.get $data3))

  ;; return ptr
  (return (local.get $ptr))
)

(func $str-byte-len (param $ptr i32) (result i32)
  ;; if (ptr == 0) {
  (if (i32.eqz (local.get $ptr))
    ;; trap
    (then unreachable)
  )
  ;; }

  ;; return *ptr
  (return (i32.load (local.get $ptr)))
)

(func $str-code-point-len (param $ptr i32) (result i32)
  (local $byte-len i32) ;; the length of the string in bytes
  (local $cp-len i32) ;; the length of the string in code points
  (local $offset i32) ;; the bit offset within the current 32-bit word
  (local $word i32) ;; the current 32-bit word
  (local $byte i32) ;; the current byte

  ;; if (ptr == 0) {
  (if (i32.eqz (local.get $ptr))
    ;; trap
    (then unreachable)
  )
  ;; }

  ;; byte-len = *ptr
  (local.set $byte-len (i32.load (local.get $ptr)))
  ;; cp-len = 0
  (local.set $cp-len (i32.const 0))
  ;; offset = 0
  (local.set $offset (i32.const 0))

  ;; ptr = ptr += 4
  (%plus-eq $ptr 4)
  ;; word = *ptr
  (local.set $word (i32.load (local.get $ptr)))
  ;; while (byte-len > 0) {
  (block $b_end
    (loop $b_start
      (br_if $b_end (i32.le_s (local.get $byte-len) (i32.const 0)))
      ;; byte = (word >> offset)
      (local.set $byte (i32.shr_u (local.get $word) (local.get $offset)))

      ;; if ((byte & 0x80) == 0) {
      (if (i32.eqz (i32.and (local.get $byte) (i32.const 0x80)))
        (then
          ;; single byte
          ;; offset += 8
          (%plus-eq $offset 8)
          ;; byte-len -= 1
          (%dec $byte-len)
        )
        (else
          ;; } else if ((byte & 0xE0) == 0xC0) {
          (if (i32.eq (i32.and (local.get $byte) (i32.const 0xE0)) (i32.const 0xC0))
            (then
              ;; double byte
              ;; offset += 16
              (%plus-eq $offset 16)
              ;; byte-len -= 2
              (%minus-eq $byte-len 2)
            )
            (else
            ;; } else if ((byte & 0xF0) == 0xE0) {
              (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF0)) (i32.const 0xE0))
                (then
                  ;; triple byte
                  ;; offset += 24
                  (%plus-eq $offset 24)
                  ;; byte-len -= 3
                  (%minus-eq $byte-len 3)
                )
                (else
                  ;; } else if ((byte & 0xF8) == 0xF0) {
                  (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF8)) (i32.const 0xF0))
                    (then
                      ;; offset += 32
                      (%plus-eq $offset 32)
                      ;; byte-len -= 4
                      (%minus-eq $byte-len 4)
                    )
                    ;; } else {
                    (else
                      ;; trap
                      unreachable
                      ;; }
                    )
                  )
                )
              )
            )
          )
        )
      )

      ;; cp-len++
      (%inc $cp-len)

      ;; if (offset >= 32) {
      (if (i32.ge_u (local.get $offset) (i32.const 32))
        (then
          ;; ptr += 4
          (%plus-eq $ptr 4)
          ;; word = *ptr
          (local.set $word (i32.load (local.get $ptr)))
          ;; offset -= 32
          (%minus-eq $offset 32)
        )
        ;; }
      )
      
      (br $b_start)
    )
  ;; }
  )

  ;; return cp-len
  (return (local.get $cp-len))
)

(func $get-bytes (param $ptr i32) (param $end i32) (param $offset i32) (param $get-len i32) (result i32)
  (local $quad i64)
  ;; quad = *ptr
  ;; if (end - ptr > 4) {
  (if (i32.gt_s (i32.sub (local.get $end) (local.get $ptr)) (i32.const 4))
    (then
      ;; quad = (i64*)ptr
      (local.set $quad (i64.load (local.get $ptr)))
    )
  ;; } else {
    (else
      ;; quad = (i64)(i64*)ptr
      (local.set $quad (i64.extend_i32_u (i32.load (local.get $ptr))))
    )
  ;; }
  )

  ;; return (quad >> offset) & (-1 >> ((8-len) * 8))
  (return (i32.wrap_i64 (i64.and
    (i64.shr_u (local.get $quad) (i64.extend_i32_u (local.get $offset)))
    (i64.shr_u 
      (i64.const -1)
      (i64.extend_i32_u (i32.mul
        (i32.sub (i32.const 8) (local.get $get-len))
        (i32.const 8)
      ))
    )
  )))
)

(func $str-code-point-at (param $ptr i32) (param $at i32) (result i32)
  (local $byte-len i32) ;; the byte length of the string
  (local $cp-len i32)   ;; the length of the string in code points
  (local $offset i32)   ;; the bit offset within the current word
  (local $word i32)     ;; the current 32-bit word
  (local $byte i32)     ;; the current byte
  (local $char i32)     ;; the current encoded character
  (local $end i32)      ;; ptr to end of string
  ;; if (ptr == 0) {
  (if (i32.eqz (local.get $ptr))
    ;; trap
    (then unreachable)
  )
  ;; }

  ;; byte-len = *ptr
  (local.set $byte-len (i32.load (local.get $ptr)))
  ;; cp-len = 0
  (local.set $cp-len (i32.const 0))
  ;; offset = 0
  (local.set $offset (i32.const 0))

  ;; ptr += 4
  (%plus-eq $ptr 4)
  (local.set $end (i32.add (local.get $ptr) (local.get $byte-len)))
  ;; word = *ptr
  (local.set $word (i32.load (local.get $ptr)))
  ;; while (byte-len > 0) {
  (block $b_end
    (loop $b_start
      (br_if $b_end (i32.le_s (local.get $byte-len) (i32.const 0)))
      ;; byte = (word >> offset)
      (local.set $byte (i32.shr_u (local.get $word) (local.get $offset)))

      ;; if ((byte & 0x80) == 0) {
      (if (i32.eqz (i32.and (local.get $byte) (i32.const 0x80)))
        (then
          ;; single byte
          ;; if (cp-len == at) {
          (if (i32.eq (local.get $cp-len) (local.get $at))
          ;;   return (byte & 0x7F)
            (return (i32.and (local.get $byte) (i32.const 0x7F)))
          ;; }
          )
          ;; offset += 8
          (%plus-eq $offset 8)
          ;; byte-len -= 1
          (%dec $byte-len)
        )
        (else
          ;; } else if ((byte & 0xE0) == 0xC0) {
          (if (i32.eq (i32.and (local.get $byte) (i32.const 0xE0)) (i32.const 0xC0))
            (then
              ;; double byte
              ;; if (cp-len == at) {
              (if (i32.eq (local.get $cp-len) (local.get $at))
                (then
                  ;; char = get-bytes(ptr, end, offset, 2) 
                  (local.set $char (call $get-bytes
                    (local.get $ptr) 
                    (local.get $end) 
                    (local.get $offset) 
                    (i32.const 2)
                  ))
                  ;; 0b110xxxxx 0b10xxxxxx
                  ;; return ((char & 0x1f) << 6) | ((char & 0x3F00) >> 8)
                  (return (i32.or
                    (i32.shl (i32.and (local.get $char) (i32.const 0x1F)) (i32.const 6))
                    (i32.shr_u (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 8))
                  ))
                )
              ;; }
              )
              ;; offset += 16
              (%plus-eq $offset 16)
              ;; byte-len -= 2
              (%minus-eq $byte-len 2)
            )
            (else
              ;; } else if ((byte & 0xF0) == 0xE0) {
              (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF0)) (i32.const 0xE0))
                (then
                  ;; triple byte
                  ;; if (cp-len == at) {
                  (if (i32.eq (local.get $cp-len) (local.get $at))
                    (then
                      ;; char = get-bytes(ptr, end, offset, 3) 
                      (local.set $char (call $get-bytes
                        (local.get $ptr) 
                        (local.get $end) 
                        (local.get $offset) 
                        (i32.const 3)
                      ))
                      ;; 0b1110xxxx 0b10xxxxxx 0b10xxxxxx
                      ;; return ((char & 0xF) << 12) | ((char & 0x3f00) >> 2) | ((char & 0x3f0000) >> 16)
                      (return 
                        (i32.or 
                          (i32.or
                            (i32.shl (i32.and (local.get $char) (i32.const 0xF)) (i32.const 12))
                            (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f00)) (i32.const 2)) ;; >> 8 then << 6
                          )
                          (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 16))
                        )
                      )
                    )
                  ;; }
                  )
                  ;; offset += 24
                  (%plus-eq $offset 24)
                  ;; byte-len -= 3
                  (%minus-eq $byte-len 3)
                )
                (else
                  ;; } else if ((byte & 0xF8) == 0xF0) {
                  (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF8)) (i32.const 0xF0))
                    (then
                      ;; quad byte
                      ;; if (cp-len == at) {
                      (if (i32.eq (local.get $cp-len) (local.get $at))
                        (then
                          ;; char = get-bytes(ptr, end, offset, 4) 
                          (local.set $char (call $get-bytes
                            (local.get $ptr) 
                            (local.get $end) 
                            (local.get $offset) 
                            (i32.const 4)
                          ))
                          ;; 0b11110xxx 0b10xxxxxx 0b10xxxxxx 0b10xxxxxx
                          ;; return ((char & 0x7) << 18) | ((char & 0x3f00) << 4) | ((char & 0x3f0000) >> 10) | ((char & 0x3f000000) >> 24)
                          (return
                            (i32.or
                              (i32.or
                                (i32.or
                                  (i32.shl (i32.and (local.get $char) (i32.const 0x7)) (i32.const 18))
                                  (i32.shl (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 4)) ;; >> 8 then << 12
                                )
                                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 10)) ;; >> 16 then << 6
                              )
                              (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f000000)) (i32.const 24))
                            )
                          )
                        )
                      ;; }
                      )
                      ;; offset += 32
                      (%plus-eq $offset 32)
                      ;; byte-len -= 4
                      (%minus-eq $byte-len 4)
                    )
                    (else
                      ;; } else {
                      ;;   trap
                      unreachable
                      ;; }
                    )
                  )
                )
              )
            )
          )
        )
      )

      ;; cp-len++
      (%inc $cp-len)

      ;; if (offset >= 32) {
      (if (i32.ge_u (local.get $offset) (i32.const 32))
        (then
          ;; ptr += 4
          (%plus-eq $ptr 4)
          ;; word = *ptr
          (local.set $word (i32.load (local.get $ptr)))
          ;; offset -= 32
          (%minus-eq $offset 32)
        )
      ;; }
      )

      (br $b_start)
    )
  ;; }
  )

  ;; return -1
  (return (i32.const -1))
)

(func $str-is-valid (param $ptr i32) (result i32)
  (local $byte-len i32) ;; the byte length of the string
  (local $offset i32)   ;; the bit offset within the current word
  (local $word i32)     ;; the current 32-bit word
  (local $byte i32)     ;; the current byte
  (local $char i32)     ;; the current encoded character
  (local $end i32)      ;; ptr to the end of the string
  ;; if (ptr == 0) {
  (if (i32.eqz (local.get $ptr))
    ;; trap
    (then unreachable)
  )
  ;; }

  ;; byte-len = *ptr
  (local.set $byte-len (i32.load (local.get $ptr)))
  ;; offset = 0
  (local.set $offset (i32.const 0))

  ;; ptr += 4
  (%plus-eq $ptr 4)
  ;; end = ptr + byte-len
  (local.set $end (i32.add (local.get $ptr) (local.get $byte-len)))

  ;; word = *ptr
  (local.set $word (i32.load (local.get $ptr)))
  ;; while (byte-len > 0) {
  (block $b_end
    (loop $b_start
      (br_if $b_end (i32.le_s (local.get $byte-len) (i32.const 0)))

      ;; if (offset >= 32) {
      (if (i32.ge_u (local.get $offset) (i32.const 32))
        (then
          ;; ptr += 4
          (%plus-eq $ptr 4)
          ;; word = *ptr
          (local.set $word (i32.load (local.get $ptr)))
          ;; offset -= 32
          (%minus-eq $offset 32)
        )
      ;; }
      )
      ;; byte = (word >> offset) & 0xFF
      (local.set $byte (i32.and (i32.shr_u (local.get $word) (local.get $offset)) (i32.const 0xff)))

      ;; if ((byte & 0x80) == 0) {
      (if (i32.eqz (i32.and (local.get $byte) (i32.const 0x80)))
        (then
          ;; single byte
          ;; no special validation needed
          ;; offset += 8
          (%plus-eq $offset 8)
          ;; byte-len -= 1
          (%minus-eq $byte-len 1)
        )
        (else
          ;; } else if ((byte & 0xE0) == 0xC0) {
          (if (i32.eq (i32.and (local.get $byte) (i32.const 0xE0)) (i32.const 0xC0))
            (then
              ;; double byte
              ;; if (byte-len < 2) {
              (if (i32.lt_s (local.get $byte-len) (i32.const 2))
                (then
                  ;; return 0
                  (return (i32.const 0))
                )
              ;; }
              )
              ;; char = get-bytes(ptr, end, offset, 2) 
              (local.set $char (call $get-bytes 
                (local.get $ptr) 
                (local.get $end) 
                (local.get $offset) 
                (i32.const 2)
              ))
              ;; 0b110xxxxx 0b10xxxxxx
              ;; if ((char & 0xFFFFC0E0) != 0x80C0) {
              (if (i32.ne (i32.and (local.get $char) (i32.const 0xFFFFC0E0)) (i32.const 0x80C0))
                ;; return 0
                (return (i32.const 0))
              ;;}
              )
              ;; offset += 16
              (%plus-eq $offset 16)
              ;; byte-len -= 2
              (%minus-eq $byte-len 2)
            )
            (else
              ;; } else if ((byte & 0xF0) == 0xE0) {
              (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF0)) (i32.const 0xE0))
                (then
                  ;; triple byte
                  ;; if (byte-len < 3) {
                  (if (i32.lt_s (local.get $byte-len) (i32.const 3))
                    (then
                      ;; return 0
                      (return (i32.const 0))
                    )
                  ;; }
                  )
                  ;; char = get-bytes(ptr, end, offset, 3) 
                  (local.set $char (call $get-bytes 
                    (local.get $ptr) 
                    (local.get $end) 
                    (local.get $offset) 
                    (i32.const 3)
                  ))
                  ;; 0b1110xxxx 0b10xxxxxx 0b10xxxxxx
                  ;; if ((char & 0xFFC0C0F0) != 0x80l80E0) {
                  (if (i32.ne (i32.and (local.get $char) (i32.const 0xFFC0C0F0)) (i32.const 0x8080E0))
                    ;; return 0
                    (return (i32.const 0))
                  ;;}
                  )
                  ;; offset += 24
                  (%plus-eq $offset 24)
                  ;; byte-len -= 3
                  (%minus-eq $byte-len 3)
                )
                (else
                  ;; } else if ((byte & 0xF8) == 0xF0) {
                  (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF8)) (i32.const 0xF0))
                    (then
                      ;; quad byte
                      ;; if (byte-len < 4) {
                      (if (i32.lt_s (local.get $byte-len) (i32.const 4))
                        (then
                          ;; return 0
                          (return (i32.const 0))
                        )
                      ;; }
                      )
                      ;; char = get-bytes(ptr, end, offset, 4) 
                      (local.set $char (call $get-bytes 
                        (local.get $ptr) 
                        (local.get $end) 
                        (local.get $offset) 
                        (i32.const 4)
                      ))
                      ;; 0b11110xxx 0b10xxxxxx 0b10xxxxxx 0b10xxxxxx
                      ;; if ((char & 0xC0C0C0F8) != 0x808080F0) {
                      (if (i32.ne (i32.and (local.get $char) (i32.const 0xC0C0C0F8)) (i32.const 0x808080F0))
                        (then
                          ;; return 0
                          (return (i32.const 0))
                        )
                      ;; }
                      )
                      ;; top 5 bits should be lte 0x10
                      ;; if (((char & 0x7) << 2) | ((char & 0x3000)>>12)> 0x10)
                      (if (i32.gt_u
                            (i32.or 
                              (i32.shl (i32.and (local.get $char) (i32.const 0x7)) (i32.const 2))
                              (i32.shr_u (i32.and (local.get $char) (i32.const 0x3000)) (i32.const 12))
                            )
                            (i32.const 0x10)
                          )
                        (then
                          ;; return 0
                          (return (i32.const 0))
                        )
                      ;; }
                      )
                      
                      ;; offset += 32
                      (%plus-eq $offset 32)
                      ;; byte-len -= 4
                      (%minus-eq $byte-len 4)
                    )
                    (else
                      ;; } else {
                      ;;   return 0
                      (return (i32.const 0))
                      ;; }
                    )
                  )
                )
              )
            )
          )
        )
      )

     (br $b_start)
    )
  ;; }
  )

  ;; if (byte-len < 0) {
  (if (i32.lt_s (local.get $byte-len) (i32.const 0))
    (then
      (return (i32.const 0))
    ;; return 0;
    )
  ;;}
  )

  ;; return 1
  (return (i32.const 1))
)

(func $utf8-from-code-point (param $cp i32) (result i32)
  (local $first i32)
  (local $second i32)
  (local $third i32)
  (local $fourth i32)

  ;; if (cp < 0x80) {
  (if (i32.lt_u (local.get $cp) (i32.const 0x80))
    (then
      ;; return cp
      (return (local.get $cp))
    )
  )
  ;; } else if (cp < 0x800)
  (if (i32.lt_u (local.get $cp) (i32.const 0x800))
    (then
      ;; // b110xxxxx b10xxxxxx
      ;; second = ((cp & 0x3F) | 0x8000)
      (local.set $second (i32.or (i32.and (local.get $cp) (i32.const 0x3F)) (i32.const 0x80)))
      ;; first = (((cp >> 6) & 0x1f) | 0xc0)
      (local.set $first (i32.or (i32.and (i32.shr_u (local.get $cp) (i32.const 6)) (i32.const 0x1F)) (i32.const 0xC0)))
      ;; return first | second 
      (return 
        (i32.or 
          (local.get $first) 
          (i32.shl (local.get $second) (i32.const 8))
        )
      )
    )
  )
  ;; } else if (cp >= D800 && cp <= DFFF) {
  (if (i32.ge_u (local.get $cp) (i32.const 0xd800))
    (then
      (if (i32.le_u (local.get $cp) (i32.const 0xdfff))
        (then
          ;; half of a surrogate pair, not valid in utf-8 
          ;; return 0xFFFD
          (return (call $utf8-from-code-point (i32.const 0xFFFD)))
        )
      )
    )
  )
  ;; } else if (cp < 0x10000) {
  (if (i32.lt_u (local.get $cp) (i32.const 0x10000))
    (then
  ;;   // b1110xxxx b10xxxxxx b10xxxxxx
  ;;   third = ((cp & 0x3F) | 0x80)
      (local.set $third (i32.or (i32.and (local.get $cp) (i32.const 0x3F)) (i32.const 0x80)))
  ;;   second = (((cp >> 8) & 0x3F) | 0x80)
      (local.set $second (i32.or (i32.and (i32.shr_u (local.get $cp) (i32.const 6)) (i32.const 0x3F)) (i32.const 0x80)))
  ;;   first = (((cp >> 16) * 0xF) | 0xE0)
      (local.set $first (i32.or (i32.and (i32.shr_u (local.get $cp) (i32.const 12)) (i32.const 0xF)) (i32.const 0xE0)))
  ;;   return first | second << 8 | third < 16 
      (return
        (i32.or
          (i32.or
            (local.get $first)
            (i32.shl (local.get $second) (i32.const 8))
          )
          (i32.shl (local.get $third) (i32.const 16))
        )
      )
     )
  )
  ;; } else if (pc < 0x110000)
  (if (i32.lt_u (local.get $cp) (i32.const 0x110000))
    (then
      ;; // b11110xxx b10xxxxxx b10xxxxxx b10xxxxxx
      ;; fourth = ((cp & 0x3F) | 0x80)
      (local.set $fourth (i32.or (i32.and (local.get $cp) (i32.const 0x3F)) (i32.const 0x80)))
      ;; third = (((cp >> 8) & 0x3F) | 0x80)
      (local.set $third (i32.or (i32.and (i32.shr_u (local.get $cp) (i32.const 6)) (i32.const 0x3F)) (i32.const 0x80)))
      ;; second = (((cp >> 16) & 0x3F) | 0x80)
      (local.set $second (i32.or (i32.and (i32.shr_u (local.get $cp) (i32.const 12)) (i32.const 0x3F)) (i32.const 0x80)))
      ;; first = (((cp >> 24) * 0x7) | 0xF0)
      (local.set $first (i32.or (i32.and (i32.shr_u (local.get $cp) (i32.const 18)) (i32.const 0x7)) (i32.const 0xF0)))
      ;; return first | second << 8 | third < 16 | fourth | 24
      (return
        (i32.or
          (i32.or
            (i32.or
              (local.get $first)
              (i32.shl (local.get $second) (i32.const 8))
            )
            (i32.shl (local.get $third) (i32.const 16))
          )
          (i32.shl (local.get $fourth) (i32.const 24))
        )
      )
    )
  )
  ;; } else {
  ;;   return 0xFFFD
  (return (call $utf8-from-code-point (i32.const 0xFFFD)))
  ;; }
  
)

(func $utf8-code-point-size (param $cp i32) (result i32)

  ;; if (cp < 0x80) {
  (if (i32.lt_u (local.get $cp) (i32.const 0x80))
    (then
      ;; return 1
      (return (i32.const 1))
    )
  )
  ;; } else if (cp < 0x800)
  (if (i32.lt_u (local.get $cp) (i32.const 0x800))
    (then
      ;; return 2
      (return (i32.const 2))
    )
  )
  ;; } else if (cp < 0x10000) {
  (if (i32.lt_u (local.get $cp) (i32.const 0x10000))
    (then
      ;; return 3 
      (return (i32.const 3))
    )
  )
  ;; } else if (pc < 0x110000)
  (if (i32.lt_u (local.get $cp) (i32.const 0x110000))
    (then
      ;; return 4
      (return (i32.const 4))
    )
  )
  ;; } else {
  ;; return 3 (utf8 length of 0xFFFD)
  (return (i32.const 3))
  ;; }
)

(func $str-eq (param $a i32) (param $b i32) (result i32)
  (local $a-len i32)
  (local $b-len i32)
  (local $mask i32)

  ;; if (a == b) return 1
  (if (i32.eq (local.get $a) (local.get $b))
    (then (return (i32.const 1)))
  )

  ;; a-len = *a;
  (local.set $a-len (i32.load (local.get $a)))
  ;; b-len = *b;
  (local.set $b-len (i32.load (local.get $b)))

  ;; if (a-len != b-len) return 0
  (if (i32.ne (local.get $a-len) (local.get $b-len))
    (then (return (i32.const 0)))
  )

  ;; a += 4;
  (%plus-eq $a 4)
  ;; b += 4;
  (%plus-eq $b 4)

  ;; while (a-len >= 4) {
  (block $b_end
    (loop $b_start
      ;; break if a-len < 4
      (br_if $b_end (i32.lt_u (local.get $a-len) (i32.const 4)))

      ;; if (*a != *b) return 0
      (if (i32.ne (i32.load (local.get $a)) (i32.load (local.get $b)))
        (then (return (i32.const 0)))
      )

      ;; a-len -= 4
      (%minus-eq $a-len 4)
      ;; a += 4;
      (%plus-eq $a 4)
      ;; b += 4;
      (%plus-eq $b 4)

      (br $b_start)
    )
  )
  ;; }

  ;; if (a-len) {
  (if (local.get $a-len)
    (then
      ;; mask = -1 >> ((4 - a-len) * 8)
      (local.set $mask (i32.shr_u (i32.const -1) (i32.shl (i32.sub (i32.const 4) (local.get $a-len)) (i32.const 3))))

      ;; if ((*a & mask) != (*b & mask)) return 0
      (if 
        (i32.ne
          (i32.and (i32.load (local.get $a)) (local.get $mask))
          (i32.and (i32.load (local.get $b)) (local.get $mask))
        )
        (then (return (i32.const 0)))
      )
    )
  )
  ;;}

  (return (i32.const 1))
)

(func $str-from-code-points
  (param $ptr i32)  ;; pointer to an arry of 32bit code point values
  (param $len i32)  ;; number of code points 
  (result i32)      ;; an allocated string containing all the code poitns

  (local $byte-len i32) ;; the byte length of the output string
  (local $i i32)        ;; used to index over code points
  (local $cp-ptr i32)   ;; pointer to the current code point
  (local $str i32)      ;; pointer to the output string
  (local $str-ptr i32)  ;; pointer within the output string
  (local $accum i64)    ;; used to accumulate utf8 encoded sequences of bytes
  (local $acc-len i32)  ;; the bit length of the accumulated data in accum
  (local $cp-len i32)   ;; the utf8 encoded length of the code point cp
  (local $cp i32)       ;; the current code point (when encoding)

  ;; Compute the byte length.
  ;; i = 0;
  (local.set $i (i32.const 0))
  ;; byte-len = 0
  (local.set $byte-len (i32.const 0))
  ;; cp-ptr = ptr
  (local.set $cp-ptr (local.get $ptr))

  ;; while (i < len) {
  (block $c_end
    (loop $c_start
      (br_if $c_end (i32.ge_u (local.get $i) (local.get $len)))

      ;;  byte-len += utf8-code-point-size(*cp-ptr)
      (local.set $byte-len
        (i32.add
          (local.get $byte-len)
          (call $utf8-code-point-size (i32.load (local.get $cp-ptr)))
        )
      )
      ;; i++
      (%inc $i)
      ;; cp-ptr += 4
      (%plus-eq $cp-ptr 4)
      ;; }
      (br $c_start)
    )
  )

  ;; Allocate the utf-8 encoded string
  ;; str = malloc(byte-len + 8)
  (local.set $str (call $malloc (i32.add (local.get $byte-len) (i32.const 4))))
  ;; *str = byte-len
  (i32.store (local.get $str) (local.get $byte-len))
  ;; str-ptr = str + 4;
  (local.set $str-ptr (i32.add (local.get $str) (i32.const 4)))

  ;; convert and add
  ;; i = 0;
  (local.set $i (i32.const 0))
  ;; cp-ptr = ptr
  (local.set $cp-ptr (local.get $ptr))
  ;; accum = 0;
  (local.set $accum (i64.const 0))
  ;; acc-len = 0
  (local.set $acc-len (i32.const 0))

  ;; while (i < len) {
  (block $a_end
    (loop $a_start
      (br_if $a_end (i32.ge_u (local.get $i) (local.get $len)))

      ;; cp = *cp-ptr
      (local.set $cp (i32.load (local.get $cp-ptr)))
      ;; cp-len = utf8-code-point-size(cp)
      (local.set $cp-len (call $utf8-code-point-size (local.get $cp)))
      ;; accum = accum | (utf8-from-code-point(cp) << acc-len)
      (local.set $accum
        (i64.or
          (local.get $accum)
          (i64.shl
            (i64.extend_i32_u (call $utf8-from-code-point (local.get $cp)))
            (i64.extend_i32_u (local.get $acc-len))
          )
        )
      )
      ;; acc-len += 8 * cp-len
      (local.set $acc-len
        (i32.add
          (local.get $acc-len) 
          (i32.shl (local.get $cp-len) (i32.const 3))
        )
      )
      ;; if (acc-len >= 32) {
      (if (i32.gt_u (local.get $acc-len) (i32.const 32))
        (then
          ;; *str-ptr = (i32)accum
          (i32.store (local.get $str-ptr) (i32.wrap_i64 (local.get $accum)))
          ;; str-ptr += 4
          (%plus-eq $str-ptr 4)
          ;; accum >>= 32
          (local.set $accum (i64.shr_u (local.get $accum) (i64.const 32)))
          ;; acc-len -= 32
          (%minus-eq $acc-len 32)
        )
      ;; }
      )

      (%inc $i)
      ;; cp-ptr += 4
      (%plus-eq $cp-ptr 4)
      ;; }
      (br $a_start)
    )
  )

  ;; if (acc-len > 0) {
  (if (i32.gt_u (local.get $acc-len) (i32.const 0))
    (then
      ;; *str-ptr = (i32)accum
      (i32.store (local.get $str-ptr) (i32.wrap_i64 (local.get $accum)))
    )
  ;; }
  )

  ;; return str;
  (return (local.get $str))
)

(func $str-to-code-points (param $ptr i32) (param $buffer i32) (param $len i32) (result i32)
  (local $byte-len i32) ;; the byte length of the string
  (local $cp-len i32)   ;; the length of the string in code points
  (local $offset i32)   ;; the bit offset within the current word
  (local $word i32)     ;; the current 32-bit word
  (local $byte i32)     ;; the current byte
  (local $char i32)     ;; the current encoded character
  (local $end i32)      ;; ptr to end of string
  (local $dest i32)

  ;; if (ptr == 0) {
  (if (i32.eqz (local.get $ptr))
    ;; trap
    (then unreachable)
  )
  ;; }

  ;; byte-len = *ptr
  (local.set $byte-len (i32.load (local.get $ptr)))
  ;; cp-len = 0
  (local.set $cp-len (i32.const 0))
  ;; offset = 0
  (local.set $offset (i32.const 0))
  ;; dest = buffer
  (local.set $dest (local.get $buffer))

  ;; ptr += 4
  (%plus-eq $ptr 4)
  (local.set $end (i32.add (local.get $ptr) (local.get $byte-len)))
  ;; word = *ptr
  (local.set $word (i32.load (local.get $ptr)))
  ;; while (byte-len > 0 && len > 0) {
  (block $b_end
    (loop $b_start
      (br_if $b_end (i32.le_s (local.get $byte-len) (i32.const 0)))
      (br_if $b_end (i32.eqz (local.get $len)))

      ;; byte = (word >> offset)
      (local.set $byte (i32.shr_u (local.get $word) (local.get $offset)))

      (block $b_cp
        ;; if ((byte & 0x80) == 0) {
        (if (i32.eqz (i32.and (local.get $byte) (i32.const 0x80)))
          (then
            ;; single byte
            ;; *dest = (byte & 0x7F)
            (i32.store (local.get $dest) (i32.and (local.get $byte) (i32.const 0x7F)))
            ;; offset += 8
            (%plus-eq $offset 8)
            ;; byte-len -= 1
            (%dec $byte-len)
            (br $b_cp)
          )
        )
        ;; } else if ((byte & 0xE0) == 0xC0) {
        (if (i32.eq (i32.and (local.get $byte) (i32.const 0xE0)) (i32.const 0xC0))
          (then
            ;; double byte
            ;; char = get-bytes(ptr, end, offset, 2) 
            (local.set $char (call $get-bytes
              (local.get $ptr) 
              (local.get $end) 
              (local.get $offset) 
              (i32.const 2)
            ))
            ;; 0b110xxxxx 0b10xxxxxx
            ;; *dest = ((char & 0x1f) << 6) | ((char & 0x3F00) >> 8)
            (i32.store (local.get $dest)
              (i32.or
                (i32.shl (i32.and (local.get $char) (i32.const 0x1F)) (i32.const 6))
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 8))
              )
            )
            ;; offset += 16
            (%plus-eq $offset 16)
            ;; byte-len -= 2
            (%minus-eq $byte-len 2)
            (br $b_cp)
          )
        )
        ;; } else if ((byte & 0xF0) == 0xE0) {
        (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF0)) (i32.const 0xE0))
          (then
            ;; triple byte
            ;; char = get-bytes(ptr, end, offset, 3) 
            (local.set $char (call $get-bytes
              (local.get $ptr) 
              (local.get $end) 
              (local.get $offset) 
              (i32.const 3)
            ))
            ;; 0b1110xxxx 0b10xxxxxx 0b10xxxxxx
            ;; *dest = ((char & 0xF) << 12) | ((char & 0x3f00) >> 2) | ((char & 0x3f0000) >> 16)
            (i32.store
              (local.get $dest) 
              (i32.or 
                (i32.or
                  (i32.shl (i32.and (local.get $char) (i32.const 0xF)) (i32.const 12))
                  (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f00)) (i32.const 2)) ;; >> 8 then << 6
                )
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 16))
              )
            )
            ;; offset += 24
            (%plus-eq $offset 24)
            ;; byte-len -= 3
            (%minus-eq $byte-len 3)
            (br $b_cp)
          )
        )
        ;; } else if ((byte & 0xF8) == 0xF0) {
        (if (i32.eq (i32.and (local.get $byte) (i32.const 0xF8)) (i32.const 0xF0))
          (then
            ;; quad byte
            ;; char = get-bytes(ptr, end, offset, 4) 
            (local.set $char (call $get-bytes
              (local.get $ptr) 
              (local.get $end) 
              (local.get $offset) 
              (i32.const 4)
            ))
            ;; 0b11110xxx 0b10xxxxxx 0b10xxxxxx 0b10xxxxxx
            ;; *dest = ((char & 0x7) << 18) | ((char & 0x3f00) << 4) | ((char & 0x3f0000) >> 10) | ((char & 0x3f000000) >> 24)
            (i32.store 
              (local.get $dest)
              (i32.or
                (i32.or
                  (i32.or
                    (i32.shl (i32.and (local.get $char) (i32.const 0x7)) (i32.const 18))
                    (i32.shl (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 4)) ;; >> 8 then << 12
                  )
                  (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 10)) ;; >> 16 then << 6
                )
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f000000)) (i32.const 24))
              )
            )
            ;; offset += 32
            (%plus-eq $offset 32)
            ;; byte-len -= 4
            (%minus-eq $byte-len 4)
            (br $b_cp)
          )
        )
        ;; } else {
        ;;   trap
        unreachable
        ;; }
      )

      ;; len--
      (%dec $len)
      ;; dest += 4
      (%plus-eq $dest 4)
      ;; cp-len++
      (%inc $cp-len)

      ;; if (offset >= 32) {
      (if (i32.ge_u (local.get $offset) (i32.const 32))
        (then
          ;; ptr += 4
          (%plus-eq $ptr 4)
          ;; word = *ptr
          (local.set $word (i32.load (local.get $ptr)))
          ;; offset -= 32
          (%minus-eq $offset 32)
        )
      ;; }
      )

      (br $b_start)
    )
  ;; }
  )
  
  (return (local.get $cp-len))
)

(func $str-cmp (param $left-ptr i32) (param $right-ptr i32) (param $ci i32) (result i32)
  (local $left-byte-len i32) ;; the byte length of the string
  (local $right-byte-len i32) ;; the byte length of the string
  (local $cp-len i32)   ;; the length of the string in code points
  (local $left-offset i32)   ;; the bit offset within the current word
  (local $left-word i32)     ;; the current 32-bit word
  (local $left-byte i32)     ;; the current byte
  (local $left-cp i32)     ;; the current encoded character
  (local $left-end i32)      ;; ptr to end of string
  (local $right-offset i32)   ;; the bit offset within the current word
  (local $right-word i32)     ;; the current 32-bit word
  (local $right-byte i32)     ;; the current byte
  (local $right-cp i32)     ;; the current encoded character
  (local $right-end i32)      ;; ptr to end of string
  (local $char i32)

  ;; byte-len = *ptr
  (local.set $left-byte-len (i32.load (local.get $left-ptr)))
  (local.set $right-byte-len (i32.load (local.get $right-ptr)))
  ;; cp-len = 0
  (local.set $cp-len (i32.const 0))
  ;; offset = 0
  (local.set $left-offset (i32.const 0))
  (local.set $right-offset (i32.const 0))

  ;; ptr += 4
  (%plus-eq $left-ptr 4)
  (%plus-eq $right-ptr 4)
  (local.set $left-end (i32.add (local.get $left-ptr) (local.get $left-byte-len)))
  (local.set $right-end (i32.add (local.get $right-ptr) (local.get $right-byte-len)))
  ;; word = *ptr
  (local.set $left-word (i32.load (local.get $left-ptr)))
  (local.set $right-word (i32.load (local.get $right-ptr)))
  ;; while (byte-len > 0 && len > 0) {
  (block $b_end
    (loop $b_start
      (br_if $b_end (i32.le_s (local.get $left-byte-len) (i32.const 0)))
      (br_if $b_end (i32.le_s (local.get $right-byte-len) (i32.const 0)))

      ;; byte = (word >> offset)
      (local.set $left-byte (i32.shr_u (local.get $left-word) (local.get $left-offset)))
      (local.set $right-byte (i32.shr_u (local.get $right-word) (local.get $right-offset)))

      (block $b_left_cp
        ;; if ((byte & 0x80) == 0) {
        (if (i32.eqz (i32.and (local.get $left-byte) (i32.const 0x80)))
          (then
            ;; single byte
            ;; *dest = (byte & 0x7F)
            (local.set $left-cp (i32.and (local.get $left-byte) (i32.const 0x7F)))
            ;; offset += 8
            (%plus-eq $left-offset 8)
            ;; byte-len -= 1
            (%dec $left-byte-len)
            (br $b_left_cp)
          )
        )
        ;; } else if ((byte & 0xE0) == 0xC0) {
        (if (i32.eq (i32.and (local.get $left-byte) (i32.const 0xE0)) (i32.const 0xC0))
          (then
            ;; double byte
            ;; char = get-bytes(ptr, end, offset, 2) 
            (local.set $char (call $get-bytes
              (local.get $left-ptr) 
              (local.get $left-end) 
              (local.get $left-offset) 
              (i32.const 2)
            ))
            ;; 0b110xxxxx 0b10xxxxxx
            ;; *dest = ((char & 0x1f) << 6) | ((char & 0x3F00) >> 8)
            (local.set $left-cp
              (i32.or
                (i32.shl (i32.and (local.get $char) (i32.const 0x1F)) (i32.const 6))
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 8))
              )
            )
            ;; offset += 16
            (%plus-eq $left-offset 16)
            ;; byte-len -= 2
            (%minus-eq $left-byte-len 2)
            (br $b_left_cp)
          )
        )
        ;; } else if ((byte & 0xF0) == 0xE0) {
        (if (i32.eq (i32.and (local.get $left-byte) (i32.const 0xF0)) (i32.const 0xE0))
          (then
            ;; triple byte
            ;; char = get-bytes(ptr, end, offset, 3) 
            (local.set $char (call $get-bytes
              (local.get $left-ptr) 
              (local.get $left-end) 
              (local.get $left-offset) 
              (i32.const 3)
            ))
            ;; 0b1110xxxx 0b10xxxxxx 0b10xxxxxx
            ;; *dest = ((char & 0xF) << 12) | ((char & 0x3f00) >> 2) | ((char & 0x3f0000) >> 16)
            (local.set $left-cp
              (i32.or 
                (i32.or
                  (i32.shl (i32.and (local.get $char) (i32.const 0xF)) (i32.const 12))
                  (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f00)) (i32.const 2)) ;; >> 8 then << 6
                )
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 16))
              )
            )
            ;; offset += 24
            (%plus-eq $left-offset 24)
            ;; byte-len -= 3
            (%minus-eq $left-byte-len 3)
            (br $b_left_cp)
          )
        )
        ;; } else if ((byte & 0xF8) == 0xF0) {
        (if (i32.eq (i32.and (local.get $left-byte) (i32.const 0xF8)) (i32.const 0xF0))
          (then
            ;; quad byte
            ;; char = get-bytes(ptr, end, offset, 4) 
            (local.set $char (call $get-bytes
              (local.get $left-ptr) 
              (local.get $left-end) 
              (local.get $left-offset) 
              (i32.const 4)
            ))
            ;; 0b11110xxx 0b10xxxxxx 0b10xxxxxx 0b10xxxxxx
            ;; cp = ((char & 0x7) << 18) | ((char & 0x3f00) << 4) | ((char & 0x3f0000) >> 10) | ((char & 0x3f000000) >> 24)
            (local.set $left-cp
              (i32.or
                (i32.or
                  (i32.or
                    (i32.shl (i32.and (local.get $char) (i32.const 0x7)) (i32.const 18))
                    (i32.shl (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 4)) ;; >> 8 then << 12
                  )
                  (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 10)) ;; >> 16 then << 6
                )
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f000000)) (i32.const 24))
              )
            )
            ;; offset += 32
            (%plus-eq $left-offset 32)
            ;; byte-len -= 4
            (%minus-eq $left-byte-len 4)
            (br $b_left_cp)
          )
        )
        ;; } else {
        ;;   trap
        unreachable
        ;; }
      )
      (block $b_right_cp
        ;; if ((byte & 0x80) == 0) {
        (if (i32.eqz (i32.and (local.get $right-byte) (i32.const 0x80)))
          (then
            ;; single byte
            ;; *dest = (byte & 0x7F)
            (local.set $right-cp (i32.and (local.get $right-byte) (i32.const 0x7F)))
            ;; offset += 8
            (%plus-eq $right-offset 8)
            (%dec $right-byte-len)
            (br $b_right_cp)
          )
        )
        ;; } else if ((byte & 0xE0) == 0xC0) {
        (if (i32.eq (i32.and (local.get $right-byte) (i32.const 0xE0)) (i32.const 0xC0))
          (then
            ;; double byte
            ;; char = get-bytes(ptr, end, offset, 2) 
            (local.set $char (call $get-bytes
              (local.get $right-ptr) 
              (local.get $right-end) 
              (local.get $right-offset) 
              (i32.const 2)
            ))
            ;; 0b110xxxxx 0b10xxxxxx
            ;; *dest = ((char & 0x1f) << 6) | ((char & 0x3F00) >> 8)
            (local.set $right-cp
              (i32.or
                (i32.shl (i32.and (local.get $char) (i32.const 0x1F)) (i32.const 6))
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 8))
              )
            )
            ;; offset += 16
            (%plus-eq $right-offset 16)
            (%minus-eq $right-byte-len 2)
            (br $b_right_cp)
          )
        )
        ;; } else if ((byte & 0xF0) == 0xE0) {
        (if (i32.eq (i32.and (local.get $right-byte) (i32.const 0xF0)) (i32.const 0xE0))
          (then
            ;; triple byte
            ;; char = get-bytes(ptr, end, offset, 3) 
            (local.set $char (call $get-bytes
              (local.get $right-ptr) 
              (local.get $right-end) 
              (local.get $right-offset) 
              (i32.const 3)
            ))
            ;; 0b1110xxxx 0b10xxxxxx 0b10xxxxxx
            ;; *dest = ((char & 0xF) << 12) | ((char & 0x3f00) >> 2) | ((char & 0x3f0000) >> 16)
            (local.set $right-cp
              (i32.or 
                (i32.or
                  (i32.shl (i32.and (local.get $char) (i32.const 0xF)) (i32.const 12))
                  (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f00)) (i32.const 2)) ;; >> 8 then << 6
                )
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 16))
              )
            )
            ;; offset += 24
            (%plus-eq $right-offset 24)
            (%minus-eq $right-byte-len 3)
            (br $b_right_cp)
          )
        )
        ;; } else if ((byte & 0xF8) == 0xF0) {
        (if (i32.eq (i32.and (local.get $right-byte) (i32.const 0xF8)) (i32.const 0xF0))
          (then
            ;; quad byte
            ;; char = get-bytes(ptr, end, offset, 4) 
            (local.set $char (call $get-bytes
              (local.get $right-ptr) 
              (local.get $right-end) 
              (local.get $right-offset) 
              (i32.const 4)
            ))
            ;; 0b11110xxx 0b10xxxxxx 0b10xxxxxx 0b10xxxxxx
            ;; cp = ((char & 0x7) << 18) | ((char & 0x3f00) << 4) | ((char & 0x3f0000) >> 10) | ((char & 0x3f000000) >> 24)
            (local.set $right-cp
              (i32.or
                (i32.or
                  (i32.or
                    (i32.shl (i32.and (local.get $char) (i32.const 0x7)) (i32.const 18))
                    (i32.shl (i32.and (local.get $char) (i32.const 0x3F00)) (i32.const 4)) ;; >> 8 then << 12
                  )
                  (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f0000)) (i32.const 10)) ;; >> 16 then << 6
                )
                (i32.shr_u (i32.and (local.get $char) (i32.const 0x3f000000)) (i32.const 24))
              )
            )
            ;; offset += 32
            (%plus-eq $right-offset 32)
            (%minus-eq $right-byte-len 4)
            (br $b_right_cp)
          )
        )
        ;; } else {
        ;;   trap
        unreachable
        ;; }
      )

      (if (local.get $ci)
        (then 
          (local.set $left-cp (call $char-downcase-impl (local.get $left-cp)))
          (local.set $right-cp (call $char-downcase-impl (local.get $right-cp)))
        )
      )

      (if (i32.lt_u (local.get $left-cp) (local.get $right-cp))
        (then (return (i32.const -1)))
      )
      (if (i32.gt_u (local.get $left-cp) (local.get $right-cp))
        (then (return (i32.const 1)))
      )

      ;; cp-len++
      (%inc $cp-len)

      ;; if (offset >= 32) {
      (if (i32.ge_u (local.get $left-offset) (i32.const 32))
        (then
          ;; ptr += 4
          (%plus-eq $left-ptr 4)
          ;; word = *ptr
          (local.set $left-word (i32.load (local.get $left-ptr)))
          ;; offset -= 32
          (%minus-eq $left-offset 32)
        )
      ;; }
      )
      ;; if (offset >= 32) {
      (if (i32.ge_u (local.get $right-offset) (i32.const 32))
        (then
          ;; ptr += 4
          (%plus-eq $right-ptr 4)
          ;; word = *ptr
          (local.set $right-word (i32.load (local.get $right-ptr)))
          ;; offset -= 32
          (%minus-eq $right-offset 32)
        )
      ;; }
      )

      (br $b_start)
    )
  ;; }
  )

  (if (i32.eq (local.get $left-byte-len) (local.get $right-byte-len))
    (then (return (i32.const 0)))
  )
  (return 
    (select
      (i32.const -1)
      (i32.const 1)
      (i32.lt_u (local.get $left-byte-len) (local.get $right-byte-len))
    )
  )
)

(func $str-dup (param $str i32) (result i32)
  (local $len i32)
  (local $dup i32)
  (local $dest-ptr i32)

  ;; len = *str + 4
  (local.set $len (i32.add (i32.load (local.get $str)) (i32.const 4)))
  ;; dest-ptr = dup = malloc(len)
  (local.set $dest-ptr
    (local.tee $dup
      (call $malloc (local.get $len))
    )
  )

  ;; while (len > 0) {
  (block $w_end
    (loop $w_start
      (br_if $w_end (i32.le_s (local.get $len) (i32.const 0)))

      ;; *dest-ptr = *str
      (i32.store
        (local.get $dest-ptr)
        (i32.load (local.get $str))
      )

      ;; len -=4 
      (local.set $len (i32.sub (local.get $len) (i32.const 4)))
      ;; dest-ptr += 4
      (%plus-eq $dest-ptr 4)
      ;; str += 4
      (%plus-eq $str 4)

      (br $w_start)
    )
  )
  ;; }
  
  ;; return dup
  (return (local.get $dup))
)