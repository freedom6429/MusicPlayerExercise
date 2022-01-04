//
//  ViewController.swift
//  MusicPlayerExercise
//
//  Created by Wen Luo on 2021/12/29.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    //宣告index來擷取音樂清單內特定位置的item
    var index = 0
    //使用字典物件陣列音樂的相關檔案名稱與介面需要顯示的資料
    let musics = [
        ["fileName": "allthat",
            "title": "1.All that",
         "composer": "Benjamin Tissot"
        ],
        ["fileName": "thelounge",
         "title": "2.The Lounge",
         "composer": "Benjamin Tissot"
        ],
        ["fileName": "hipjazz",
         "title": "3.Hip Jazz",
         "composer": "Benjamin Tissot"
        ],
        ["fileName": "jazzyfrenchy",
         "title": "4.Jazzy Frenchy",
         "composer": "Benjamin Tissot"
        ],
        ["fileName": "sexy",
         "title": "5.Sexy",
         "composer": "Benjamin Tissot"
        ],
        ["fileName": "funkysuspense",
         "title": "6.Funky Suspense",
         "composer": "Benjamin Tissot"
        ],
    ]
   
    //建立一個陣列來放要實際用來播放的音樂檔名
    //之後要用檔名來當成參數放到生成playItem和介面顯示的函式
    var musicsToPlay : [String] = []
    
    //IBOutlet
    //操作面板View，因為會調左上角和右上角為圓角，所以要拉出來
    @IBOutlet weak var playerPanelView: UIView!
    
    //目前播放音樂的時間slider
    @IBOutlet weak var musicProgressBarSlider: UISlider!
    
    //重複播放button
    @IBOutlet weak var loopButton: UIButton!
    
    //播放or暫停button
    @IBOutlet weak var playButton: UIButton!
    
    //音樂圖片imageView
    @IBOutlet weak var musicPicImageView: UIImageView!
    
    //音樂名稱label
    @IBOutlet weak var musicTitleLabel: UILabel!
    
    //音樂作者label
    @IBOutlet weak var composerLabel: UILabel!
    
    //音樂剩餘時間長度label
    @IBOutlet weak var durationLabel: UILabel!
    
    //音樂目前播放時間label
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    //操作面板加入圓角的函式
    func addRoundCorners (cornerRadius: Double) {
        playerPanelView.layer.cornerRadius = CGFloat(cornerRadius)
        playerPanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    //切換音樂播放時間slider的按鈕成小顆的
    func setProgressBarThumb() {
        let smallConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium, scale: .small)
        let thumb = UIImage(systemName: "circle.fill", withConfiguration: smallConfig)
        musicProgressBarSlider.setThumbImage(thumb, for: .normal)
    }
    
    //將播放暫停鈕的圖片放大，並且設定播放模式及暫停模式個別顯示的圖片
    func setPlayButtonImage() {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 65, weight: .light, scale: .large)
        let playIcon = UIImage(systemName: "play.circle.fill", withConfiguration: largeConfig)
        let pauseIcon = UIImage(systemName: "pause.circle", withConfiguration: largeConfig)
        //.normal為暫停模式，所以顯示play圖片
        playButton.setImage(playIcon, for: .normal)
        //.selected為播放模式，所以顯示pause圖片
        playButton.setImage(pauseIcon, for: .selected)
    }
    
    //將重複播放按鈕福片放大一點，並且設定重複及不重複模式個別顯示的按鈕
    func switchLoopMode() {
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular, scale: .medium)
        let loopModeOffIcon = UIImage(systemName: "repeat.circle", withConfiguration: config)
        let loopModeOnIcon = UIImage(systemName: "repeat.circle.fill", withConfiguration: config)
        //.normal為不重複模式
        loopButton.setImage(loopModeOffIcon, for: .normal)
        //.selected為重複模式
        loopButton.setImage(loopModeOnIcon, for: .selected)
    }

    //格式化顯示音樂時間的函式，以Double型態的秒數為參數
    func formatedTime(_ secs: Double) -> String {
        var timeString = ""
        let formatter = DateComponentsFormatter()
        //.positional樣式為將時間單位以冒號區分
        formatter.unitsStyle = .positional
        //只需要使用分跟秒就好
        formatter.allowedUnits = [.minute, .second]
        //不同秒數下有些需要補0所以有不同的格式
        if secs < 10 && secs >= 0 {
            timeString = "0:0\(formatter.string(from: secs)!)"
        } else if secs < 60 && secs >= 10 {
            timeString = "0:\(formatter.string(from: secs)!)"
        } else {
            timeString = formatter.string(from: secs)!
        }
        return timeString
    }
    

    let player = AVPlayer()
    var looper: AVPlayerLooper?
    
    func setMusicToPlay(fileName: String, index: Int) {
        let filePath = Bundle.main.url(forResource: fileName, withExtension: ".mp3")!
        let playItem = AVPlayerItem(url: filePath)
        player.replaceCurrentItem(with: playItem)
        musicTitleLabel.text = musics[index]["title"]!
        composerLabel.text = musics[index]["composer"]!
        let musicPicture = UIImage(named: "\(musics[index]["fileName"]!).jpeg")
        musicPicImageView.image = musicPicture
        let playItemDuration =  playItem.asset.duration.seconds
        durationLabel.text = formatedTime(0 - playItemDuration)
        musicProgressBarSlider.maximumValue = Float(playItemDuration.rounded())
    }
    
    //觀察播放音樂目前的時間函式
    func musicCurrentTime() {
        //timeScale和time照抄官方文件範例，微調為每1秒發動一次
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 1, preferredTimescale: timeScale)
        //將player掛上週期性時間觀察器，除了最後更新介面的閉包外其餘參數皆是照抄官方文件和學長姐的作業
        player.addPeriodicTimeObserver(forInterval: time, queue: .main, using: { (time) in
            //如果目前播放的item狀態是可以正常播放的才執行裡面介面更新程式
            if self.player.currentItem?.status == .readyToPlay{
                //抓取目前音樂的時間
                let currentTime = self.player.currentTime().seconds
                //計算剩下多少時間
                let leftTime =  (self.player.currentItem?.duration.seconds)! - currentTime
                //設定目前時間label的text
                self.currentTimeLabel.text = self.formatedTime(currentTime)
                //設定剩餘時間label的text，加上負號
                self.durationLabel.text = "-\(self.formatedTime(leftTime))"
                //設定音樂播放時間slider的value
                self.musicProgressBarSlider.value = Float(currentTime)
            }
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //呼際播放操作面板加入圓角函式
        addRoundCorners(cornerRadius: 60)
        //設定播放按鈕圖片
        setPlayButtonImage()
        //設定播放進度slider按鈕
        setProgressBarThumb()
        //設定重複模式按鈕圖片
        switchLoopMode()
        //將要播放的音樂檔名擷取出來放到musicsToPlay陣列
        for music in musics {
            musicsToPlay.append(music["fileName"]!)
        }
        //初始化player要播放的音樂和介面
        setMusicToPlay(fileName: musicsToPlay[0], index: 0)
        //呼叫加入播放時間觀察器函式
        musicCurrentTime()
        //播放完時自動播放下一個item，會依據是否重複播放index會自動改變或者不改變播放同一首音樂
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { (_) in
            if !self.loopButton.isSelected {
                self.index = (self.index + 1) % self.musicsToPlay.count
                self.setMusicToPlay(fileName: self.musicsToPlay[self.index], index: self.index)
            } else {
                self.setMusicToPlay(fileName: self.musicsToPlay[self.index], index: self.index)
            }
            self.player.play()
        }
    }

    //IBAction
    //播放或暫停按鈕，按一下會切換按鈕的.isSelected，若為true代表播放
    //預設進入App時為暫停模式
    @IBAction func playOrPauseButton(_ sender: UIButton) {
        if !sender.isSelected {
            player.play()
            sender.isSelected = true
        } else {
            player.pause()
            sender.isSelected = false
        }
    }
    
    //拉動播放進度slider會同時改變目前播放時間label及player的播放時間
    @IBAction func changeProgressSlider(_ sender: UISlider) {
        sender.value.round()
        let time = CMTime(value: Int64(sender.value), timescale: 1)
        currentTimeLabel.text = formatedTime(time.seconds)
        player.seek(to: time)
    }
    
    //點按next按鈕會播放下一個item，若為暫停模式也會切換成播放模式
    @IBAction func nextButton(_ sender: Any) {
        index = (index + 1) % musicsToPlay.count
        setMusicToPlay(fileName: musicsToPlay[index], index: index)
        playButton.isSelected = true
        player.play()
    }
    
    //點按previous按鈕會播放前一個item，若為暫停模式會切換成播放模式
    @IBAction func previousButton(_ sender: Any) {
        index = (index + musicsToPlay.count - 1) % musicsToPlay.count
        setMusicToPlay(fileName: musicsToPlay[index], index: index)
        playButton.isSelected = true
        player.play()
    }
    
    //點按隨機播放按鈕會從musicsToPlay中隨機挑選一首音樂播放
    @IBAction func randomMusicButton(_ sender: Any) {
        index = Int.random(in: 0...musicsToPlay.count - 1)
        setMusicToPlay(fileName: musicsToPlay[index], index: index)
    }
    
    //點按重複播放模式按鈕會切換模式，預設進入App為不重複模式
    @IBAction func loopMusicButton(_ sender: UIButton) {
        if !sender.isSelected {
            sender.isSelected = true
        } else {
            sender.isSelected = false
        }
    }
    
    //調整音量slider，滑動可調整音樂音量
    @IBAction func volumnChangeSlider(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    
}

