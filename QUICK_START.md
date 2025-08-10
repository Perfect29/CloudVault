# 🚀 CloudVault - Быстрый запуск

## Запуск одной командой

### Linux/Mac:
```bash
./start-local.sh
```

### Windows:
```cmd
start-local.bat
```

### Или вручную:
```bash
docker-compose up --build
```

## Что происходит:

1. ✅ Проверяется, что Docker запущен
2. 🛑 Останавливаются существующие контейнеры
3. 🔨 Собираются и запускаются все сервисы:
   - PostgreSQL база данных
   - Redis кэш
   - Spring Boot backend
   - React frontend
   - Nginx (опционально)

## Доступ к приложению:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **База данных**: localhost:5432

⏱️ **Время запуска: 2-3 минуты**

## Остановка:

```bash
docker-compose down
```

## Логи:

```bash
docker-compose logs -f
```

---

**Готово!** Приложение будет работать локально сразу после запуска контейнеров.