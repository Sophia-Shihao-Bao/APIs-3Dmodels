import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var gifUrl: URL?

    var body: some View {
        VStack {
            if let gifUrl = gifUrl {
                AsyncImage(url: gifUrl) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                } placeholder: {
                    ProgressView()
                        .frame(width: 300, height: 300)
                }
                .padding()
            } else {
                Text("No GIF loaded yet")
                    .padding()
            }

            Button("Fetch Random Gif") {
                fetchRandomGif()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Adding Balls view
            Balls()
                .frame(height: 400) // Adjust as needed for layout
        }
        .padding()
    }

    func fetchRandomGif() {
        let apiKey = "rr4g0oTzopLtAbo3rc9KZx2RI7NaGIGS"
        guard let url = URL(string: "https://api.giphy.com/v1/gifs/random?api_key=\(apiKey)") else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching GIF: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let response = try JSONDecoder().decode(RandomGiphyResponce.self, from: data)
                DispatchQueue.main.async {
                    self.gifUrl = URL(string: response.data.images.fixed_height.url)
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }
        task.resume()
    }
}

struct Balls: View {
    @State private var scale = false

    var body: some View {
        RealityView { content in
            for _ in 1...5 {
                let model = ModelEntity(
                    mesh: .generateSphere(radius: 0.025),
                    materials: [SimpleMaterial(color: .red, isMetallic: true)]
                )

                // Randomize position
                let x = Float.random(in: -0.2...0.2)
                let y = Float.random(in: -0.2...0.2)
                let z = Float.random(in: -0.2...0.2)
                model.position = SIMD3(x, y, z)

                // interactions
                model.components.set(InputTargetComponent())
                model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.025)]))
                content.add(model)
            }
        } update: { content in
            content.entities.forEach { entity in
                entity.transform.scale = scale ? SIMD3<Float>(2, 2, 2) : SIMD3<Float>(1, 1, 1)
            }
        }
        .gesture(
            TapGesture().targetedToAnyEntity().onEnded { _ in
                scale.toggle()
            }
        )
    }
}

struct RandomGiphyResponce: Codable {
    let data: Gif
}

struct Gif: Codable {
    let images: GifImages
}

struct GifImages: Codable {
    let fixed_height: GifUrl
}

struct GifUrl: Codable {
    let url: String
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
