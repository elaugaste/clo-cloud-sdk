# Форсируем версию OpenAPI 3.0.0 для совместимости с oapi-codegen
.openapi = "3.0.0" |
# 1. Исправление вложенных массивов в тегах
( .paths[]? | .[]? | select(has("tags")) | .tags ) |= map(if type == "array" then .[0] else . end) |

# 2. Установка корректного сервера
.servers = [{"url": $api_url, "description": "Production API"}] |

# 3. Добавление схемы безопасности
. + {"security": [{"bearerAuth": []}]} |
.components.securitySchemes = {"bearerAuth": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT"}} |

# 4. Добавление 400 ошибки, если нет 4xx ответов
(.paths[]? | .[]? | select(has("responses")) | .responses) |= (
    if (keys | map(startswith("4")) | any | not)
    then . + {"400": {"description": "Bad Request"}}
    else .
    end
) | 
# 5. Добавляем схему ApiError
.components.schemas += {
  "ApiError": {
    "type": "object",
    "properties": {
      "message": { "type": "string" },
      "code": { "type": "integer" },
      "description": { "type": "string" }
    },
    "required": ["message", "code", "description"] 
  }
} |

# 6. Проставляем ссылки на ApiError для всех 4xx и 5xx ответов во всех путях
(.paths[]? | .[]? | .responses? | select(. != null)) |= with_entries(
  if (.key | tonumber? // 0) >= 400 then
    .value.content."application/json".schema = { "$ref": "#/components/schemas/ApiError" }
  else 
    . 
  end
)
