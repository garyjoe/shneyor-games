<div dir="rtl">

# Shneyor Games

מאגר של משחקי תלת־ממד לדפדפן, בנויים ב־[Godot 4](https://godotengine.org) (גרסה לפי `.godot-version`).

## מבנה

| נתיב | תוכן |
| --- | --- |
| `games/<שם>/` | פרויקט Godot נפרד לכל משחק |
| `site/` | דף הבית שמציג את רשימת המשחקים |
| `scripts/build.sh` | מייצא את כל המשחקים לדפדפן אל `dist/` |
| `.github/workflows/deploy.yml` | בנייה אוטומטית ופרסום ל־GitHub Pages בכל דחיפה ל־`main` |

## עבודה על משחק

פותחים את `games/game-01/project.godot` בעורך של Godot ולוחצים F5.
שליטה במשחק הדוגמה: חיצים או WASD לתנועה, רווח לקפיצה.

## בנייה מקומית לדפדפן

דורש Godot עם תבניות הייצוא ל־Web (בעורך: Editor ← Manage Export Templates).

```bash
scripts/build.sh
```

```bash
python3 -m http.server --directory dist 8000
```

## הוספת משחק חדש

1. מעתיקים את `games/game-01` לתיקייה חדשה תחת `games/`.
2. משנים את `config/name` ואת `config/description` בקובץ `project.godot`.

המשחק ייבנה ויופיע בדף הבית אוטומטית.

## פרסום

ב־GitHub: ‏Settings ← Pages ← Source: **GitHub Actions**. מאותו רגע כל דחיפה ל־`main` מפרסמת את האתר.

</div>
