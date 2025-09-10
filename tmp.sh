if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo ERROR: ANTHROPIC_API_KEY is not set
  exit 1
fi
echo "All good"