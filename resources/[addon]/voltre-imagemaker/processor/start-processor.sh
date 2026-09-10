#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║     null IMAGE MAKER - Démarrage du processeur      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")"

if [ ! -f "package.json" ]; then
    echo "❌ Erreur: package.json introuvable"
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances Node.js..."
    npm install
    echo ""
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)

if [ "$NODE_VERSION" -lt 18 ]; then
    echo "⚠️  Attention: Node.js $NODE_VERSION détecté (minimum requis: 18)"
    echo "   Le processeur peut ne pas fonctionner correctement."
    echo ""
    read -p "   Continuer quand même ? (o/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
        exit 1
    fi
fi

echo "🚀 Démarrage du processeur..."
echo ""

node processor.js
