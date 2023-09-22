package rinha

import "core:os"
import "core:strings"
import "core:fmt"
import "core:text/match"

import "core:c"

foreign import lib "stdlib"


@(default_calling_convention="c")
foreign lib {
  system :: proc(command: cstring) -> int ---
}

TokenType :: enum {
  // Single-character tokens.
  LEFT_PAREN, RIGHT_PAREN,
  LEFT_BRACE, RIGHT_BRACE,
  // COMMA, DOT,
  MINUS, PLUS,
  // SEMICOLON, SLASH, STAR,

  // One or two character tokens.
  BANG, BANG_EQUAL,
  EQUAL, EQUAL_EQUAL,
  GREATER, GREATER_EQUAL,
  LESS, LESS_EQUAL,
  ARROW,

  // Literals.
  IDENTIFIER, STRING, NUMBER,

  // Keywords.
  // AND, FALSE, FOR, NIL, OR, TRUE,
  PRINT, LET, IF, ELSE, FN,

  EOF,
}

keywords := map[string]TokenType {
	"print" = TokenType.PRINT,
	"if" = TokenType.IF,
	"else" = TokenType.ELSE,
  "fn" = TokenType.FN,
}

Token :: struct {
  type: TokenType,
  lexeme: string,
}

is_letter :: proc(char : rune) -> bool {
  return (char >= 'a' && char <= 'z') || 
         (char >= 'A' && char <= 'Z') || 
         char == '_'
}

main :: proc() {
  data, ok := os.read_entire_file("sum.rinha", context.allocator)
	if !ok { return }
	defer delete(data, context.allocator)

	source := string(data)
  tokens := [dynamic]Token {}

	for line in strings.split_lines_iterator(&source) {
    index := 0

    for index < len(line) {
      char := rune(line[index])
      index += 1
      
      switch char {
        case '(': append(&tokens, Token{TokenType.LEFT_PAREN, "("})
        case ')': append(&tokens, Token{TokenType.RIGHT_PAREN, ")"})
        case '{': append(&tokens, Token{TokenType.LEFT_BRACE, "{"})
        case '}': append(&tokens, Token{TokenType.RIGHT_BRACE, "}"})
        // case ',': add_token(TokenType.COMMA)
        // case '.': add_token(TokenType.DOT)
        case '-': append(&tokens, Token{TokenType.MINUS, "-"})
        case '+': append(&tokens, Token{TokenType.PLUS, "+"})
        // case ';': add_token(TokenType.SEMICOLON)
        // case '*': add_token(TokenType.STAR)

        // case '!':
        //   index += 1
        //   add_token(rune(line[index]) == '=' ? TokenType.BANG_EQUAL : TokenType.BANG)
        case '=':
          index += 1 // @review bound check?
          if rune(line[index]) == '=' {
            append(&tokens, Token{TokenType.EQUAL_EQUAL, "=="})
          } else if rune(line[index]) == '>' {
            append(&tokens, Token{TokenType.ARROW, "=>"})
          } else {
            append(&tokens, Token{TokenType.EQUAL, "="})
          }

        // case '<':
        //   index += 1
        //   add_token(rune(line[index]) == '=' ? TokenType.LESS_EQUAL : TokenType.LESS)
        // case '>':
        //   index += 1
        //   add_token(rune(line[index]) == '=' ? TokenType.GREATER_EQUAL : TokenType.GREATER)

        case '"':
          builder := strings.builder_make()

          next_char := rune(line[index])
          for next_char != '"' {
            strings.write_rune(&builder, next_char)
            index += 1
            next_char = rune(line[index])
          }
          // Skip closing quote: "
          index += 1

          append(&tokens, Token{TokenType.STRING, strings.to_string(builder)})

        case:
          if is_letter(char) {
            builder := strings.builder_make()
            strings.write_rune(&builder, char)

            next_char := char
            for index < len(line) && is_letter(next_char) {
              next_char = rune(line[index])
              strings.write_rune(&builder, next_char)
              index += 1
            }
            // index -= 1

            identifier := strings.trim(strings.to_string(builder), " ")
            if identifier in keywords {
              append(&tokens, Token{keywords[identifier], identifier})
            } else {
              append(&tokens, Token{TokenType.IDENTIFIER, identifier})
            }

            // fmt.println(strings.to_string(builder))
          }
      }
    }
	}

  for token in tokens {
    fmt.printf("%s: %s\n", token.type, token.lexeme)
  }

  // @review
  if os.exists("program.odin") {
    os.remove("program.odin")
  }

  fd, error := os.open("program.odin", os.O_CREATE | os.O_RDWR, 777)
  
  os.write_string(fd, "package program\nimport \"core:fmt\"\n")
  os.write_string(fd, "main :: proc() {\n")

  for token in tokens {
    #partial switch token.type {
      case TokenType.PRINT:
        os.write_string(fd, "fmt.")
        os.write_string(fd, token.lexeme)
      case TokenType.STRING:
        os.write_string(fd, "\"")
        os.write_string(fd, token.lexeme)
        os.write_string(fd, "\"")
      case TokenType.LEFT_PAREN:
        os.write_string(fd, "(")
      case TokenType.RIGHT_PAREN:
        os.write_string(fd, ")")
    }
  }

  os.write_string(fd, "\n}")

  os.close(fd)

  // fmt.println("Running program...")
  // system("odin run program.odin -file")
}
