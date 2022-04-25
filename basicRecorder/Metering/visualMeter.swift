
import SwiftUI

struct visualMeter: View {
    var level: Float = 0.0
    var mySquares: meterSquares = meterSquares()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)
            self.mySquares
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
    }
    
    init(level: Float = 100.0) {
        self.level = level
        self.mySquares.updateSquares(level: level)
    }
}

struct meterSquares: View {
    var squareArray: Array<meterSquare> = []
    var numSquares: Int
    
    var body: some View {
        HStack {
            ForEach(0..<20) { i in
                squareArray[i]
            }
        }
        .padding()
    }
    
    init(numSquares: Int = 20) {
        self.numSquares = numSquares
        
        for i in 1...numSquares {
            if i < 16 {
                self.squareArray.append(meterSquare(colorIndex: 0))
            } else if i < 20 {
                self.squareArray.append(meterSquare(colorIndex: 1))
            } else {
                self.squareArray.append(meterSquare(colorIndex: 2))
            }
        }
    }
    
    mutating func updateSquares(level: Float) {
        // level must be from 0.0 to 1.0
        var currentLevel = level
        for i in 0..<20 {
            if currentLevel > 0 {
                if !self.squareArray[i].isTurnedOn() {
                    self.squareArray[i].toggle()
                }
            } else {
                if self.squareArray[i].isTurnedOn() {
                    self.squareArray[i].toggle()
                }
            }
            currentLevel -= 0.05
        }
    }
}

struct meterSquare: View {
    var onColor: Color
    var offColor: Color
    var turnedOn: Bool = false
    
    var body: some View {
        if self.turnedOn {
            Rectangle()
                .fill(onColor)
                .border(Color.black)
        } else {
            Rectangle()
                .fill(offColor)
                .border(Color.black)
        }
    }
    
    init(colorIndex: Int) {
        self.onColor = colorArray[colorIndex][0]
        self.offColor = colorArray[colorIndex][1]
    }
    
    mutating func toggle() {
        if self.turnedOn {
            self.turnedOn = false
        } else {
            self.turnedOn = true
        }
    }
    
    func isTurnedOn() -> Bool {
        return self.turnedOn
    }
    
    
}

struct visualMeter_Previews: PreviewProvider {
    static var previews: some View {
        visualMeter()
    }
}
