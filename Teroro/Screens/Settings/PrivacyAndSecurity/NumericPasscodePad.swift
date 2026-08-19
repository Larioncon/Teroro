import SwiftUI

struct NumericPasscodePad: View {
    let onDigit: (String) -> Void

    private let letters = [
        "1": "",
        "2": "A B C",
        "3": "D E F",
        "4": "G H I",
        "5": "J K L",
        "6": "M N O",
        "7": "P Q R S",
        "8": "T U V",
        "9": "W X Y Z",
        "0": ""
    ]

    var body: some View {
        VStack(spacing: 20) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]], id: \.self) { row in
                HStack(spacing: 30) {
                    ForEach(row, id: \.self) { digit in
                        PasscodeKeyButton(digit: digit, letters: letters[digit] ?? "", onDigit: onDigit)
                    }
                }
            }

            PasscodeKeyButton(digit: "0", letters: "", onDigit: onDigit)
        }
    }
}
