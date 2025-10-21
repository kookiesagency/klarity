# Deploying to Vercel

This guide explains how to deploy your Flutter web app to Vercel.

## Prerequisites

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Make sure you have Flutter installed and web support enabled (already done)

## Deployment Options

### Option 1: Deploy using Vercel CLI (Recommended)

1. Build the Flutter web app:
```bash
flutter build web --release
```

2. Deploy to Vercel:
```bash
vercel --prod
```

When prompted:
- Select or create a new project
- For "Which directory is your code located?" enter: `./`
- Vercel will automatically detect the `vercel.json` configuration

### Option 2: Deploy via Vercel Dashboard

1. Build the Flutter web app:
```bash
flutter build web --release
```

2. Push your code to GitHub (including build/web folder):
   - First, modify `.gitignore` to allow build/web:
   ```bash
   # Add this line to .gitignore to allow only web builds
   /build/*
   !/build/web/
   ```

3. Connect your GitHub repository to Vercel:
   - Go to https://vercel.com
   - Click "Add New Project"
   - Import your GitHub repository
   - Vercel will use the `vercel.json` configuration

### Option 3: GitHub Actions + Vercel (Continuous Deployment)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter build web --release

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: \${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: \${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: \${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./build/web
```

## Important Notes

1. **Build Output**: The build output is in `build/web/` directory
2. **Single Page Application**: The `vercel.json` configures routing to support Flutter's SPA behavior
3. **Database**: Since this app uses SQLite (Sqflite), the database features **will not work on web** as SQLite is not supported in web browsers. You'll need to:
   - Use a web-compatible database (e.g., IndexedDB via Hive or Isar)
   - Or connect to a backend API with a database
4. **Platform-specific features**: Some Flutter plugins may not work on web (biometrics, file system, etc.)

## Testing Locally

Before deploying, test the web build locally:

```bash
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Then visit http://localhost:8000

## Troubleshooting

If you encounter issues:

1. Clear Flutter build cache:
```bash
flutter clean
flutter pub get
flutter build web --release
```

2. Check Vercel deployment logs in the Vercel dashboard

3. Ensure all dependencies support web platform
