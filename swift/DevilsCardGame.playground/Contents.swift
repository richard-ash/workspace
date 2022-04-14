import UIKit

// Devil's Card Game
// https://twitter.com/10kdiver/status/1514241744350507013?s=20&t=CHRZmZBpxxiPMtjFcQXBgQ

func doBackwardsInduction() {
    var solvedRound: Int = 11
    var takeHomeMultiple: Double = 1

    while solvedRound > 1 {
        let roundBeingSolved = solvedRound - 1

        let c1: Double = 2047 / 2048
        let c2: Double = pow(2.0, Double(11 - roundBeingSolved))

        // In round roundBeingSolved, we have y and are betting g*y
        // If we draw a double => we earn takeHomeMultiple * y(1+g)
        // If we draw a demon => we earn c2 * y * (1 - c1*g)
        // Therefore setting the two outcomes to be equal to one another
        // We get takeHomeMultiple * y(1+g) = c2 * y * (1 - c1*g)
        // takeHomeMultiple + takeHomeMultiple*g = c2 - c2*c1*g
        // g*(takeHomeMultiple + c2*c1) = (c2 - takeHomeMultiple)
        // g = (c2 - takeHomeMultiple) / (takeHomeMultiple + c2*c1)
        let g = (c2 - takeHomeMultiple) / (takeHomeMultiple + c2 * c1)
        solvedRound = roundBeingSolved
        takeHomeMultiple *= (1 + g)

        let s = (11 - roundBeingSolved) > 1 ? "s" : ""
        print("\n")
        print(
        """
        If we have \(11 - roundBeingSolved) double\(s) and 1 devil on deck, we bet
        ~\(String(format: "%.4f", g*100))% of our bankroll. And we're guaranteed to take home ~\(String(format: "%.4f", takeHomeMultiple))
        times whatever money we enter this round with.
        """
        )
    }

}

doBackwardsInduction()
