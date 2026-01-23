# Исправление вложенных массивов в тегах
( .paths[]? | .[]? | select(has("tags")) | .tags ) |= map(if type == "array" then .[0] else . end) | 

# Установка корректного сервера
.servers = [{"url": $api_url, "description": "Production API"}] | 

# Добавление схемы безопасности
. + {"security": [{"bearerAuth": []}]} | 
.components.securitySchemes = {"bearerAuth": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT"}} | 

# Добавление 400 ошибки, если нет 4xx ответов
(.paths[]? | .[]? | select(has("responses")) | .responses) |= (
    if (keys | map(startswith("4")) | any | not) 
    then . + {"400": {"description": "Bad Request"}} 
    else . 
    end
)
