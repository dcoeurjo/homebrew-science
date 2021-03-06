class Alpscore < Formula
  desc "Applications and Libraries for Physics Simulations"
  homepage "http://alpscore.org"
  url "https://github.com/ALPSCore/ALPSCore/archive/v0.5.5.tar.gz"
  sha256 "23612813734e6bf8c3fdabd58f6d71cebbe9e9cbfec80e84880099761789dbc7"
  revision 2
  head "https://github.com/ALPSCore/ALPSCore.git"

  bottle do
    cellar :any
    sha256 "9cabfec752f0cd1851a53d0cbb55eb3d8348f82ca887d17ae1536f149f702c66" => :sierra
    sha256 "930052b5933c8497c60b89d68703eaaf1dd24cd18067f5250515cb995ca782a5" => :el_capitan
    sha256 "f53e5dab2e6963e1ce13a184b00ac09025a717aa6d14cbeaea5464be5dfb940f" => :yosemite
  end

  option :cxx11
  option "with-test",   "Build and run shipped tests"
  option "with-doc",    "Build documentation"
  option "with-static", "Build static instead of shared libraries"

  depends_on "cmake" => :build
  depends_on :mpi => [:cc, :cxx, :recommended]

  boost_options = []
  boost_options << "c++11" if build.cxx11?
  depends_on "boost" => boost_options

  depends_on "hdf5" => (build.cxx11? ? ["c++11"] : [])

  def install
    ENV.cxx11 if build.cxx11?
    args = std_cmake_args
    args.delete "-DCMAKE_BUILD_TYPE=None"
    args << "-DCMAKE_BUILD_TYPE=Release"

    if build.with? "static"
      args << "-DALPS_BUILD_STATIC=ON"
      args << "-DALPS_BUILD_SHARED=OFF"
    else
      args << "-DALPS_BUILD_STATIC=OFF"
      args << "-DALPS_BUILD_SHARED=ON"
    end

    args << ("-DENABLE_MPI=" + ((build.with? "mpi") ? "ON" : "OFF"))
    args << ("-DDocumentation=" + ((build.with? "doc") ? "ON" : "OFF"))
    args << ("-DTesting=" + ((build.with? "test") ? "ON" : "OFF"))

    mkdir "tmp" do
      args << ".."
      system "cmake", *args
      system "make"
      system "make", "test" if build.with? "test"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <alps/mc/api.hpp>
      #include <alps/mc/mcbase.hpp>
      #include <alps/accumulators.hpp>
      #include <alps/params.hpp>
      using namespace std;

      int main()
      {
        alps::accumulators::accumulator_set set;
        set << alps::accumulators::FullBinningAccumulator<double>("a");
        set["a"] << 2.9 << 3.1;

        alps::params p;
        p["myparam"] = 1.0;
      }
    EOS
    args_compile = [
      "test.cpp",
      "-lalps-accumulators", "-lalps-hdf5", "-lalps-utilities", "-lalps-params",
      "-lboost_filesystem-mt", "-lboost_system-mt", "-lboost_program_options-mt"
    ]
    args_compile << "-o" << "test"
    system ((build.with? "mpi") ? "mpicxx" : ENV.cxx), *args_compile
    system "./test"
  end
end
