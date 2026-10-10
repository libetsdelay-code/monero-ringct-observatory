// size_probe: report the on-wire serialized SIZE (bytes) of Monero's privacy
// proofs, using Monero's own serialization. Size is deterministic (not
// hardware-dependent), so these numbers are final regardless of host.
//
// Built as an extra target inside Monero's tests/performance_tests (see
// Dockerfile.size), so it links the same libs and uses the real rct code.
#include <cstdio>
#include <cstddef>
#include <string>
#include <vector>

#include "ringct/rctTypes.h"
#include "ringct/rctOps.h"
#include "ringct/bulletproofs.h"
#include "ringct/bulletproofs_plus.h"
#include "serialization/binary_utils.h"

using namespace rct;

template <class T>
static size_t blobsize(T &o) {
  std::string blob;
  serialization::dump_binary(o, blob);
  return blob.size();
}

int main() {
  const std::vector<size_t> out_counts = {1, 2, 4, 8, 16};
  const std::vector<size_t> ring_sizes = {2, 4, 8, 11, 16, 32, 64};

  // Bulletproofs(+) range-proof size vs number of outputs aggregated.
  for (size_t M : out_counts) {
    std::vector<uint64_t> v(M, 1000);
    keyV gamma(M);
    for (auto &g : gamma) g = skGen();

    BulletproofPlus bpp = bulletproof_plus_PROVE(v, gamma);
    printf("bulletproof_plus outputs=%zu size_bytes=%zu\n", M, blobsize(bpp));

    Bulletproof bp = bulletproof_PROVE(v, gamma);
    printf("bulletproof outputs=%zu size_bytes=%zu\n", M, blobsize(bp));
  }

  // CLSAG size vs ring size. Serialized fields are s (n scalars), c1, D
  // (I is reconstructed, not serialized). Size depends only on n.
  for (size_t n : ring_sizes) {
    clsag c;
    c.s = keyV(n, zero());
    c.c1 = zero();
    c.I = identity();
    c.D = identity();
    printf("clsag ring=%zu size_bytes=%zu\n", n, blobsize(c));
  }
  return 0;
}
