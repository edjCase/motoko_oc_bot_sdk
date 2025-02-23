import { test } "mo:test";
import Debug "mo:base/Debug";
import Der "../src/DER";

test(
    "der",
    func() {
        let testCases : [(Text, ?Der.DerPublicKey)] = [
            (
                "-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEHSCs05IjAzFrHHLuFvTiL2Seer8R
SW37uqX8DP2bzeJ5vyiwiWtbpcFoPemColnzogXkZLDE40wC1SCtAScCsA==
-----END PUBLIC KEY-----",
                ?{
                    key = [
                        0x00,
                        0x04,
                        0x1d,
                        0x20,
                        0xac,
                        0xd3,
                        0x92,
                        0x23,
                        0x03,
                        0x31,
                        0x6b,
                        0x1c,
                        0x72,
                        0xee,
                        0x16,
                        0xf4,
                        0xe2,
                        0x2f,
                        0x64,
                        0x9e,
                        0x7a,
                        0xbf,
                        0x11,
                        0x49,
                        0x6d,
                        0xfb,
                        0xba,
                        0xa5,
                        0xfc,
                        0x0c,
                        0xfd,
                        0x9b,
                        0xcd,
                        0xe2,
                        0x79,
                        0xbf,
                        0x28,
                        0xb0,
                        0x89,
                        0x6b,
                        0x5b,
                        0xa5,
                        0xc1,
                        0x68,
                        0x3d,
                        0xe9,
                        0x82,
                        0xa2,
                        0x59,
                        0xf3,
                        0xa2,
                        0x05,
                        0xe4,
                        0x64,
                        0xb0,
                        0xc4,
                        0xe3,
                        0x4c,
                        0x02,
                        0xd5,
                        0x20,
                        0xad,
                        0x01,
                        0x27,
                        0x02,
                        0xb0,
                    ];
                    algorithm = {
                        oid = "1.2.840.10045.2.1";
                        parameters = ?"1.2.840.10045.3.1.7";
                    };
                    bitString = {
                        tag = 0x03;
                        length = 66;
                        totalBytes = 68;
                    };
                    sequence = {
                        tag = 0x30;
                        length = 89;
                        totalBytes = 91;
                    };
                },
            ),
        ];
        for ((keyText, expected) in testCases.vals()) {
            let actual = Der.parsePublicKey(keyText);
            if (actual != expected) {
                Debug.trap("keyText: " # keyText # "\nexpected: " # debug_show (expected) # "\nactual: " # debug_show (actual));
            };
        };
    },
);
