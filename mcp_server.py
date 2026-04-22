#!/usr/bin/env python3
"""
MCP Shell Server
Exposes a run_command tool over SSE transport (port 8765).
Allows Claude (or any MCP-compatible client) to execute shell commands
directly inside the Docker container.
"""
import subprocess
import logging
import uvicorn
from mcp.server.fastmcp import FastMCP

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [MCP] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

mcp = FastMCP("shell-server")


@mcp.tool()
def run_command(command: str) -> str:
    """
    Executes a shell command inside the container (/app working directory).
    Returns stdout + stderr. Maximum timeout: 5 minutes.
    """
    logger.info(f"▶ {command}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            cwd="/app",
            timeout=300,
        )
        output = result.stdout
        if result.stderr:
            output += f"\n[stderr]\n{result.stderr}"
        if not output.strip():
            output = f"[exit code: {result.returncode}]"
        return output
    except subprocess.TimeoutExpired:
        return "[ERROR] Command cancelled: exceeded the 5-minute timeout."
    except Exception as e:
        return f"[ERROR] {e}"


if __name__ == "__main__":
    logger.info("MCP Shell Server starting on 0.0.0.0:8765 ...")
    app = mcp.sse_app()
    uvicorn.run(app, host="0.0.0.0", port=8765, log_level="info")
