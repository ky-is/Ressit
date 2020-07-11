import SwiftUI

struct BlurView: UXViewRepresentable {
	let style: UIBlurEffect.Style

	func makeUIView(context: Context) -> UXView {
		let view = UXView(frame: .zero)
		view.backgroundColor = .clear
		let blurEffect = UIBlurEffect(style: style)
		let blurView = UIVisualEffectView(effect: blurEffect)
		blurView.translatesAutoresizingMaskIntoConstraints = false
		view.insertSubview(blurView, at: 0)
		NSLayoutConstraint.activate([
			blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
			blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
		])
		return view
	}

	func updateUIView(_ view: UIView, context: Context) {
	}
}

struct BlurView_Previews: PreviewProvider {
	static var previews: some View {
		BlurView(style: .systemChromeMaterial)
	}
}

