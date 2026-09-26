# FIX «0 MB» error when downloading acts in Shadow Fight 2
# Починка ошибки «0 МБ» при скачивании актов в Shadow Fight 2

**Fix 0 MB error downloading** — Shadow Fight 2 acts no longer download on old clients; this fixes it.
**Фикс ошибки «0 МБ»** — в старых версиях не качаются акты (главы); это лечит проблему.

Video tutorial (Android, by JOHN BULLET): <https://www.youtube.com/watch?v=K22WRwT8VB0>

Live mirror / живое зеркало: <https://sf2-acts.vercel.app/config_SF2.xml>

---

## 🇷🇺 Русский

### FIX ошибки «0 МБ» при скачивании актов (глав) в Shadow Fight 2

> **Fix «0 MB» error when downloading acts** — лечим ошибку «0 МБ», из-за которой
> не качаются главы.

При переходе к новой главе игра докачивает данные («акты») с сервера Nekki. Этот
сервер раздачи умер, поэтому на старых версиях игры загрузка главы падает с
ошибкой **«0 МБ»** — игра просто не получает список файлов главы. Лечится это
заменой адреса конфига в одном файле на живое зеркало
`config_SF2.xml`.

### Что нужно

- Игра версии **1.8.0 или новее**, с пройденным обучением.
- Доступ к файлам игры:
  - **Android** — root + RootExplorer (или любой файловый менеджер с root).
    На части версий в теории срабатывает и без root: создайте папку `assets` в
    корне памяти телефона и положите туда `internalSettings.xml` — но это только
    в теории и не на всех версиях.
  - **iOS** — джейлбрейк + **iFile** или **Filza**. Без джейлбрейка так не
    выйдет.

### Метод (пример: iOS 1.9.15, 32-bit)

1. Сделайте джейлбрейк и установите iFile/Filza.
2. Откройте `/var/mobile/Applications` и найдите папку игры.
3. Перейдите: `Library` → `Caches` → `assets`.
4. Найдите файл `internalSettings.xml` и откройте его текстовым редактором.
5. Найдите строку:

   ```xml
   <DefaultConfigUrl Url="..." />
   ```

6. Замените **только значение `Url`** на адрес зеркала — остальное в строке не
   трогайте:

   ```xml
   <DefaultConfigUrl Url="https://sf2-acts.vercel.app/config_SF2.xml" />
   ```

7. Сохраните файл и **удалите** рядом лежащий `internalSettings.xml.hash`.
8. Запустите игру — появится **«data error»** или похожее сообщение, нажмите
   **reload**, после чего всё заработает.

### Android

Для большинства версий нужен root: зайдите в
`data/data/com.nekki.shadowfight` (точный путь зависит от версии), найдите там
`internalSettings.xml` и замените адрес так же, как выше.

**Способ без root (на Android):** создайте папку `assets` в корне памяти
телефона и положите туда `internalSettings.xml` — возможно, игра подхватит файл
оттуда. Это только в теории и работает не на всех версиях, зато **без root**.

### Видеоурок (Android) и полное описание

- Полное описание этого способа: <https://github.com/creepyfaiz/shadow-fight-2-0mb-fix>
- Видеоурок для **Android** от автора **JOHN BULLET**:
  <https://www.youtube.com/watch?v=K22WRwT8VB0>
- Способ для **iOS** — **позже**.

### Запасной адрес

Если наше зеркало недоступно, можно указать адрес автора оригинала:

```xml
<DefaultConfigUrl Url="http://johnbullet.kesug.com/config_SF2.xml" />
```

### Важно

- Способ может отличаться на разных версиях игры — **главное найти
  `internalSettings.xml`**.
- Меняйте **только** значение `Url`. Остальное в строке (и в файле) не трогайте —
  иначе игра может не запуститься.

### Контроль целостности конфига

| | |
|---|---|
| Источник | `http://johnbullet.kesug.com/config_SF2.xml` |
| Размер | 145160 байт |
| MD5 | `6e28619456754b74f2d3245f6add79a9` |
| SHA-256 | `3dc0feba2ee1703b7f7b3f436d7a8bc331966378173af6093ebbe323a7800c05` |
| Копия снята | 2026-09-26 |

Зеркало: `https://sf2-acts.vercel.app/config_SF2.xml`

### Права

Игра и её данные принадлежат **Nekki**. Это личный архивный бэкап файла, без
коммерческого использования.

---

## 🇬🇧 English

### Fix "0 MB" error when downloading acts (chapters) in Shadow Fight 2

> **Fix «0 MB» error when downloading acts** — this fixes the "0 MB" error that
> stops chapters from downloading.

When you move to a new chapter, the game downloads data ("acts") from Nekki's
server. That distribution server is dead, so on older versions loading a chapter
fails with a **"0 MB"** error — the game simply never receives the chapter's list
of files. The fix is to replace the config address in one file with a live mirror
of `config_SF2.xml`.

### What you need

- The game at version **1.8.0 or newer**, with the tutorial completed.
- Access to the game files:
  - **Android** — root + RootExplorer (or any file manager with root). On some
    versions it can theoretically work without root: create an `assets` folder in
    the root of phone storage and put `internalSettings.xml` there — but that is
    theory only and not on every version.
  - **iOS** — a jailbreak + **iFile** or **Filza**. Without a jailbreak this won't
    work.

### The method (example: iOS 1.9.15, 32-bit)

1. Jailbreak the device and install iFile/Filza.
2. Open `/var/mobile/Applications` and find the game's folder.
3. Go: `Library` → `Caches` → `assets`.
4. Find the file `internalSettings.xml` and open it in a text editor.
5. Find the line:

   ```xml
   <DefaultConfigUrl Url="..." />
   ```

6. Replace **only the `Url` value** with the mirror address — leave the rest of
   the line untouched:

   ```xml
   <DefaultConfigUrl Url="https://sf2-acts.vercel.app/config_SF2.xml" />
   ```

7. Save the file and **delete** the neighbouring `internalSettings.xml.hash`.
8. Launch the game — you'll see **"data error"** or something similar, press
   **reload**, and everything works.

### Android

Most versions need root: go to `data/data/com.nekki.shadowfight` (the exact path
depends on the version), find `internalSettings.xml` there and replace the address
the same way as above.

**No-root option (Android):** create an `assets` folder in the root of phone
storage and put `internalSettings.xml` there — the game may pick the file up from
there. This is theory only and doesn't work on every version, but it needs **no
root**.

### Video tutorial (Android) and full write-up

- Full description of this method: <https://github.com/creepyfaiz/shadow-fight-2-0mb-fix>
- **Android** video tutorial by the author **JOHN BULLET**:
  <https://www.youtube.com/watch?v=K22WRwT8VB0>
- The **iOS** method is **coming later**.

### Backup address

If our mirror is unavailable, you can point it to the original author's address:

```xml
<DefaultConfigUrl Url="http://johnbullet.kesug.com/config_SF2.xml" />
```

### Important

- The method may differ across game versions — **the main thing is to find
  `internalSettings.xml`**.
- Change **only** the `Url` value. Leave everything else in the line (and in the
  file) alone — otherwise the game may fail to start.

### Config integrity

| | |
|---|---|
| Source | `http://johnbullet.kesug.com/config_SF2.xml` |
| Size | 145160 bytes |
| MD5 | `6e28619456754b74f2d3245f6add79a9` |
| SHA-256 | `3dc0feba2ee1703b7f7b3f436d7a8bc331966378173af6093ebbe323a7800c05` |
| Copied on | 2026-09-26 |

Mirror: `https://sf2-acts.vercel.app/config_SF2.xml`

### Rights

The game and its data belong to **Nekki**. This is a personal archival backup of
the file, with no commercial use.
