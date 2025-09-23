#!/usr/bin/env python3
import asyncio
from process import process

async def main():
  a = await process()
  print(a)

if __name__ == "__main__":
  asyncio.run(main())
