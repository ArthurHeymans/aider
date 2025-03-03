{
  description = "Aider - AI pair programming in your terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python3 = pkgs.python312.override {
          self = python3;
          packageOverrides = _: super: { tree-sitter = super.tree-sitter_0_21; };
        };

        pythonEnv = python3.withPackages (
          ps: with ps; [
            aiohappyeyeballs
            aiohttp
            aiosignal
            annotated-types
            anyio
            attrs
            backoff
            beautifulsoup4
            certifi
            cffi
            charset-normalizer
            click
            configargparse
            diff-match-patch
            diskcache
            distro
            filelock
            flake8
            frozenlist
            fsspec
            gitdb
            gitpython
            grep-ast
            h11
            httpcore
            httpx
            huggingface-hub
            idna
            importlib-resources
            jinja2
            jiter
            json5
            jsonschema
            jsonschema-specifications
            litellm
            markdown-it-py
            markupsafe
            mccabe
            mdurl
            mixpanel
            multidict
            networkx
            numpy
            openai
            packaging
            pathspec
            pexpect
            pillow
            prompt-toolkit
            psutil
            ptyprocess
            pycodestyle
            pycparser
            pydantic
            pydantic-core
            pydub
            pyflakes
            pygments
            pypandoc
            pyperclip
            python-dotenv
            pyyaml
            referencing
            regex
            requests
            rich
            rpds-py
            scipy
            smmap
            sniffio
            sounddevice
            soundfile
            soupsieve
            tiktoken
            tokenizers
            tqdm
            tree-sitter
            tree-sitter-languages
            typing-extensions
            urllib3
            watchfiles
            wcwidth
            yarl
            zipp
            pip
            # Not listed in requirements but needed
            monotonic
            posthog
            propcache
            python-dateutil
            setuptools-scm
            # Help requirements
            llama-index-core
            llama-index-embeddings-huggingface
            greenlet
          ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.gitMinimal
            pkgs.portaudio
            pkgs.stdenv.cc.cc.lib  # Adds libstdc++
          ];

          shellHook = ''
            export AIDER_CHECK_UPDATE=false
            export AIDER_ANALYTICS=false
            export PYTHONPATH=$PWD:$PYTHONPATH
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
          '';
        };

        packages.default = 
          let
            version = pkgs.lib.removeSuffix "\n" (builtins.readFile (
              pkgs.runCommand "version" { } ''
                cd ${self}
                ${pkgs.gitMinimal}/bin/git describe --tags --abbrev=0 > $out || echo "v0.0.0" > $out
              ''
            ));
          in
          pkgs.python312.pkgs.buildPythonPackage {
            pname = "aider-chat";
            version = pkgs.lib.removePrefix "v" version;
            pyproject = true;

          src = ./.;

          pythonRelaxDeps = true;

          build-system = with pkgs.python312.pkgs; [ setuptools-scm ];

          buildInputs = [ pkgs.portaudio pkgs.stdenv.cc.cc.lib ];

          nativeCheckInputs = (with pkgs.python312.pkgs; [ pytestCheckHook ]) ++ [ pkgs.gitMinimal ];

          makeWrapperArgs = [
            "--set AIDER_CHECK_UPDATE false"
            "--set AIDER_ANALYTICS false"
          ];

          meta = with pkgs.lib; {
            description = "AI pair programming in your terminal";
            homepage = "https://github.com/paul-gauthier/aider";
            license = licenses.asl20;
            mainProgram = "aider";
          };
        };
      }
    );
}
