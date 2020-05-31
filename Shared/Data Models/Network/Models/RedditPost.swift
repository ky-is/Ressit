import Foundation

struct RedditPost: RedditResponsable, RedditIdentifiable {
	static let type = "t3"

	let id: String
	let hashID: String
	let title: String
	let author: String
	let score: Int
	let commentCount: Int
	let createdAt: TimeInterval
	let editedAt: TimeInterval?
	let saved: Bool
	let likes: Bool?
	let url: URL?
	let selftext: String
	let thumbnail: String?
	let crosspostID: String?
	let crosspostFrom: String?

	let previewURLs: [URL]?
	let previewIsVideo: Bool
	let previewWidth: Float?
	let previewHeight: Float?

	init(json: Any) {
		let data = Self.defaultJSONData(json)
		id = data["id"] as! String
		let urlString = data["url"] as? String
		url = urlString != nil ? URL(string: urlString!) : nil
		title = data["title"] as! String
		selftext = data["selftext"] as! String
		let isSelf = data["is_self"] as! Bool
		hashID = getHashID(isSelf: isSelf,id: id, url: url, title: title, selftext: selftext)
//		print(json, hashID) //SAMPLE
		author = data["author"] as! String
		score = data["score"] as! Int
		commentCount = data["num_comments"] as! Int
		createdAt = data["created"] as! TimeInterval
		let editTimestamp = data["edited"] as! TimeInterval
		editedAt = editTimestamp > 0 ? editTimestamp : nil
		saved = data["saved"] as! Bool
		likes = data["likes"] as? Bool
		let thumbnail = data["thumbnail"] as? String
		self.thumbnail = thumbnail != "self" ? thumbnail : nil

		var previewURLStrings: [String]?
		var isPreviewVideo = false
		var previewWidth: Float?, previewHeight: Float?

		let mediaContainerData: [String: Any]
		crosspostID = data["crosspost_parent"] as? String
		if let crossposts = data["crosspost_parent_list"] as? [[String: Any]], let crosspost = crossposts.first {
			mediaContainerData = crosspost
			crosspostFrom = crosspost["subreddit"] as? String
		} else {
			mediaContainerData = data
			crosspostFrom = nil
		}
		if let media = mediaContainerData["media"] as? [String: Any] {
			if let video = parseRedditMedia(key: "reddit_video", from: media) {
				isPreviewVideo = true
				previewURLStrings = [video.0]
				previewWidth = video.1
				previewHeight = video.2
			}
		}

		if previewURLStrings == nil, let previews = data["preview"] as? [String: Any] {
			if let video = parseRedditMedia(key: "reddit_video_preview", from: previews) {
				isPreviewVideo = true
				previewURLStrings = [video.0]
				previewWidth = video.1
				previewHeight = video.2
			}
			if previewURLStrings == nil, let images = previews["images"] as? [[String: Any]] {
				previewURLStrings = images.compactMap { image in
					let base: [String: Any]
					if let variants = image["variants"] as? [String: Any], let videoVariant = (variants["mp4"] ?? variants["gif"]) as? [String: Any] {
						base = videoVariant
						isPreviewVideo = true
					} else {
						base = image
					}
					guard let source = base["source"] as? [String: Any], let urlString = source["url"] as? String else {
						print("images", image)
						return nil
					}
					if previewWidth == nil {
						previewWidth = source["width"] as? Float
						previewHeight = source["height"] as? Float
					}
					return urlString
				}
			}
		}
		self.previewURLs = previewURLStrings?.compactMap(URL.init(string:)).nonEmpty
		self.previewIsVideo = isPreviewVideo
		self.previewWidth = previewWidth
		self.previewHeight = previewHeight
	}
}

private func parseRedditMedia(key: String, from json: [String: Any]) -> (String, Float?, Float?)? {
	if let videoPreview = json[key] as? [String: Any] {
		if let urlString = (videoPreview["hls_url"] ?? videoPreview["fallback_url"]) as? String {
			return (urlString, videoPreview["width"] as? Float, videoPreview["height"] as? Float)
		}
		print(key, "unavailable", videoPreview)
	}
	return nil
}

private func getHashID(isSelf: Bool, id: String, url: URL?, title: String, selftext: String?) -> String {
	if isSelf {
		if let selftext = selftext {
			let text = title + selftext
			if text.count > 2, let md5 = text.md5 {
				return md5
			}
		}
	} else if let url = url?.deletingPathExtension() {
		if let host = url.host, host.count >= 3 {
			let hostString = host.starts(with: "www.") ? String(host.dropFirst(4)) : host
			return hostString + url.path
		}
		if url.path.count > 2 {
			return url.path
		}
	}
	return id
}
