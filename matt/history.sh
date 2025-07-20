# Run stable diffusion example
curl -LsSf https://astral.sh/uv/install.sh | sh
git clone https://github.com/tinygrad/tinygrad
cd tinygrad
PYTHONPATH="." uv run --with pillow --with numpy examples/stable_diffusion.py

# Attempting to make docs work, with some chatgpt help to create a pyproject.toml
vim mkdocs.yml
uv pip install mkdocs-material mkdocstrings[python]
uv pip install mkdocs-material mkdocstrings
./serve_docs.sh
uv pip install callouts
./serve_docs.sh
cat setup.py
# I copied setup.py and send to chatgpt to convert into a pyproject.toml file
cat setup.py | pbcopy
pbpaste > pyproject.toml
uv pip install .[testing]
uv pip install '.[testing]'
uv pip install '.[testing_minimal]'
./serve_docs.sh
uv pip install '.[docs]'
./serve_docs.sh

# Try YOLO object detection
source .venv/bin/activate
uv pip install opencv-python
PYTHONPATH="." python examples/yolov8.py ~/Downloads/andy-playroom-1.png
open outputs_yolov8/andy-playroom-1_output.png

# try tinychat example
cat README.md
vim examples/llama3.py
source .venv/bin/activate
python examples/llama3.py
uv pip install tiktoken
python examples/llama3.py
PYTHONPATH="." python examples/llama3.py
uv pip install blobfile
PYTHONPATH="." python examples/llama3.py
uv pip install bottle
PYTHONPATH="." python examples/llama3.py

# Check out the tensor graph visualizer
PORT=8001 NOOPT=0 DEBUG=2 VIZ=1 PYTHONPATH="." python test/test_tiny.py TestTiny.test_gemm

# Boiling
PYTHONPATH="." python boiler/boil.py python examples/beautiful_mnist.py

# Syncing files to toqbot
rsync -avz matt/ root@toqbot.com:tinygrad/matt/
