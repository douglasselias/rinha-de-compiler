package rinha

import "core:os"
import "core:strings"
import "core:c"
import "core:fmt"

foreign import lib "stdlib"

@(default_calling_convention="c")
foreign lib {
  system :: proc(command: cstring) -> int ---
}

TokenType :: enum {
  // Single-character tokens.
  LEFT_PAREN, RIGHT_PAREN,
  LEFT_BRACE, RIGHT_BRACE,
  MINUS, PLUS, ASTERISK, SLASH,
  MODULO,
  COMMA,
  SEMICOLON,

  // One or two character tokens.
  BANG, BANG_EQUAL,
  EQUAL, EQUAL_EQUAL, NOT_EQUAL,
  GREATER, GREATER_EQUAL,
  LESS, LESS_EQUAL,
  ARROW,

  // Literals.
  IDENTIFIER, STRING, INT, FLOAT,

  // Keywords.
  AND, OR, 
  PRINT, LET, IF, ELSE, FN,

  EOF,
}

keywords := map[string]TokenType {
	"print" = TokenType.PRINT,
	"if" = TokenType.IF,
	"else" = TokenType.ELSE,
  "fn" = TokenType.FN,
  "let" = TokenType.LET,
}

Token :: struct {
  type: TokenType,
  lexeme: string,
}

is_letter :: proc(char: rune) -> bool {
  return (char >= 'a' && char <= 'z') || 
         (char >= 'A' && char <= 'Z') || 
         char == '_'
}

is_number :: proc(char: rune) -> bool {
  return char >= '0' && char <= '9'
}

main :: proc() {
  data, ok := os.read_entire_file(os.args[1], context.allocator)
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
        case '-': append(&tokens, Token{TokenType.MINUS, "-"})
        case '+': append(&tokens, Token{TokenType.PLUS, "+"})
        case ',': append(&tokens, Token{TokenType.COMMA, ","})
        case ';': append(&tokens, Token{TokenType.SEMICOLON, ";"})
        case '*': append(&tokens, Token{TokenType.ASTERISK, "*"})
        case '/': append(&tokens, Token{TokenType.SLASH, "/"})
        case '%': append(&tokens, Token{TokenType.MODULO, "%"})

        case '!':
          if rune(line[index]) == '=' {
            append(&tokens, Token{TokenType.NOT_EQUAL, "!="})
            index += 1 // Skip second token
          }
        case '=':
          if rune(line[index]) == '=' {
            append(&tokens, Token{TokenType.EQUAL_EQUAL, "=="})
            index += 1 // Skip second token
          } else if rune(line[index]) == '>' {
            append(&tokens, Token{TokenType.ARROW, "=>"})
            index += 1 // Skip second token
          } else {
            append(&tokens, Token{TokenType.EQUAL, "="})
          }
        case '<':
          if rune(line[index]) == '=' {
            append(&tokens, Token{TokenType.LESS_EQUAL, "<="})
            index += 1 // Skip second token
          } else {
            append(&tokens, Token{TokenType.LESS, "<"})
          }
        case '>':
          if rune(line[index]) == '=' {
            append(&tokens, Token{TokenType.GREATER_EQUAL, ">="})
            index += 1 // Skip second token
          } else {
            append(&tokens, Token{TokenType.GREATER, ">"})
          }
        case '|':
          if rune(line[index]) == '|' {
            append(&tokens, Token{TokenType.OR, "||"})
            index += 1 // Skip second token
          }
        case '&':
          if rune(line[index]) == '&' {
            append(&tokens, Token{TokenType.AND, "&&"})
            index += 1 // Skip second token
          }
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
          if is_number(char) {
            builder := strings.builder_make()
            strings.write_rune(&builder, char)

            for index < len(line) {
              char = rune(line[index])
              if is_number(char) || char == '.' {
                strings.write_rune(&builder, char)
                index += 1
              } else { break }
            }

            number := strings.trim(strings.to_string(builder), " ")
            if strings.contains_rune(number, '.') {
              append(&tokens, Token{TokenType.FLOAT, number})
            } else {
              append(&tokens, Token{TokenType.INT, number})
            }
          } else if is_letter(char) {
            builder := strings.builder_make()
            strings.write_rune(&builder, char)

            for index < len(line) {
              char = rune(line[index])
              if is_letter(char) {
                strings.write_rune(&builder, char)
                index += 1
              } else { break }
            }

            identifier := strings.trim(strings.to_string(builder), " ")
            if identifier in keywords {
              append(&tokens, Token{keywords[identifier], identifier})
            } else {
              append(&tokens, Token{TokenType.IDENTIFIER, identifier})
            }
          }
      }
    }
	}

  if os.exists("build/program.rb") {
    os.remove("build/program.rb")
  }

  system("mkdir -p build")
  fd, error := os.open("build/program.rb", os.O_CREATE | os.O_RDWR, 777)
  os.write_string(fd, `def create_tuple(fst, snd)
  return [fst, snd]
end

def first(tuple)
  return tuple[0]
end

def second(tuple)
  return tuple[1]
end
`)
  
  program := [dynamic]string {}

  index := 0
  for index < len(tokens) {
    #partial switch tokens[index].type {
      case TokenType.SEMICOLON:
        append(&program, "\n")
      case TokenType.PRINT:
        append(&program, "\nprint")
        if tokens[index + 2].type == TokenType.LEFT_PAREN {
          append(&program, "(create_tuple(")
          index += 3 // First
          append(&program, tokens[index].lexeme)
          index += 1 // Comma
          append(&program, tokens[index].lexeme)
          index += 1 // Second
          append(&program, tokens[index].lexeme)
          index += 1 // Right paren
          append(&program, tokens[index].lexeme)
        }
      case TokenType.STRING:
        append(&program, strings.concatenate({"\"", tokens[index].lexeme, "\""}))
      case TokenType.LET:
        if tokens[index + 3].type == TokenType.FN {
          append(&program, "def ")
          index += 1
          append(&program, tokens[index].lexeme)
          index += 2 // Skip = token
        } else if tokens[index + 3].type == TokenType.LEFT_PAREN {
          index += 1
          append(&program, tokens[index].lexeme)
          append(&program, " = create_tuple(")
          index += 2// Skip = token
        }
    
      case TokenType.LEFT_BRACE:
        append(&program, " \n")
      case TokenType.RIGHT_BRACE:
        if tokens[index + 1].type != TokenType.ELSE {
          append(&program, "\nend\n")
        }
      case TokenType.ARROW: fallthrough
      case TokenType.FN: 
        append(&program, " ")
      case TokenType.LEFT_PAREN: append(&program, tokens[index].lexeme)
      case TokenType.RIGHT_PAREN: append(&program, tokens[index].lexeme)
      case TokenType.INT: append(&program, tokens[index].lexeme)
      case TokenType.FLOAT: append(&program, tokens[index].lexeme)
      case TokenType.COMMA: append(&program, tokens[index].lexeme)
      case TokenType.IDENTIFIER:
        append(&program, tokens[index].lexeme)

        if index + 2 < len(tokens) && tokens[index + 2].type == TokenType.LEFT_PAREN {
          index += 1
          append(&program, tokens[index].lexeme)
          append(&program, "(create_tuple(")
          index += 2 // First
          append(&program, tokens[index].lexeme)
          index += 1 // Comma
          append(&program, tokens[index].lexeme)
          index += 1 // Second
          append(&program, tokens[index].lexeme)
          index += 1 // Right paren
          append(&program, "))")
        }
      case TokenType.ELSE: fallthrough
      case TokenType.IF:
        append(&program, strings.concatenate({"\n", tokens[index].lexeme, " "}))
      case TokenType.EQUAL: fallthrough
      case TokenType.EQUAL_EQUAL: fallthrough
      case: 
        append(&program, strings.concatenate({" ", tokens[index].lexeme, " "}))
        
    }
    index += 1
  }

  for token in program {
    os.write_string(fd, token)
  }

  os.close(fd)

  system("ruby build/program.rb")
}
