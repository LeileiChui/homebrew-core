require "language/node"
require "json"

class Webpack < Formula
  desc "Bundler for JavaScript and friends"
  homepage "https://webpack.js.org/"
  url "https://registry.npmjs.org/webpack/-/webpack-5.67.0.tgz"
  sha256 "bb10fb95162e0b18d1688c72519b338a4d76e3ff63163e74204a4a855d7e0619"
  license "MIT"
  head "https://github.com/webpack/webpack.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "63336e96db79e15b6c4a97e06f7507b043816011f74ed573d10d3addfb1336b0"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "63336e96db79e15b6c4a97e06f7507b043816011f74ed573d10d3addfb1336b0"
    sha256 cellar: :any_skip_relocation, monterey:       "4a31c2ac9cdee3310412a8cb76a4fd6ad22a0c1bed274c91bb0eafdcb09d6579"
    sha256 cellar: :any_skip_relocation, big_sur:        "4a31c2ac9cdee3310412a8cb76a4fd6ad22a0c1bed274c91bb0eafdcb09d6579"
    sha256 cellar: :any_skip_relocation, catalina:       "4a31c2ac9cdee3310412a8cb76a4fd6ad22a0c1bed274c91bb0eafdcb09d6579"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "dada2a21ad3d1cfc6ebb39c73dc02117f2e6b4579ef92126c9342e6a94a61ddd"
  end

  depends_on "node"

  resource "webpack-cli" do
    url "https://registry.npmjs.org/webpack-cli/-/webpack-cli-4.9.1.tgz"
    sha256 "0e80f38d28019f7c30f7237ca0b7a250dfe0b561d07d8248b162dde663cd54ff"
  end

  def install
    (buildpath/"node_modules/webpack").install Dir["*"]
    buildpath.install resource("webpack-cli")

    cd buildpath/"node_modules/webpack" do
      system "npm", "install", *Language::Node.local_npm_install_args, "--legacy-peer-deps"
    end

    # declare webpack as a bundledDependency of webpack-cli
    pkg_json = JSON.parse(File.read("package.json"))
    pkg_json["dependencies"]["webpack"] = version
    pkg_json["bundleDependencies"] = ["webpack"]
    File.write("package.json", JSON.pretty_generate(pkg_json))

    system "npm", "install", *Language::Node.std_npm_install_args(libexec)

    bin.install_symlink libexec/"bin/webpack-cli"
    bin.install_symlink libexec/"bin/webpack-cli" => "webpack"

    # Replace universal binaries with their native slices
    deuniversalize_machos
  end

  test do
    (testpath/"index.js").write <<~EOS
      function component() {
        const element = document.createElement('div');
        element.innerHTML = 'Hello' + ' ' + 'webpack';
        return element;
      }

      document.body.appendChild(component());
    EOS

    system bin/"webpack", "bundle", "--mode", "production", "--entry", testpath/"index.js"
    assert_match "const e=document\.createElement(\"div\");", File.read(testpath/"dist/main.js")
  end
end
