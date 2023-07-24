//==========================================================================================
// PROGRAMMERS: Luis K. Pena, Waseem Hussain Syed, Jorge Cortes and David Parra
//
// CLASS: COP4655
// SECTION: RVCC
// SEMESTER: Summer 2023
// CLASSTIME: Online
//
// Project: Space CATDet is a single player game in short bursts where the player
//          will try to catch as many space fish on screen as possible in a set
//          amount of time.
//
// CERTIFICATION: I understand FIU’s academic policies, and I certify that this work is my
//                 own and that none of it is the work of any other person.
//==========================================================================================

//Imports
import SpriteKit
import GameplayKit
import AVFoundation

//This is the main game scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Private global variables
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var player: SKSpriteNode!
    private var enemy: SKSpriteNode!
    private var isPlayerJumping = false
    private var scoreLabel: SKLabelNode!
    private var playButton: SKSpriteNode!
    private var gameStarted = false
    private var score = 0
    private var isMovingPlayer = false
    
    //Masks for sprites
    private let playerCategory: UInt32 = 0x1 << 0
    private let enemyCategory: UInt32 = 0x1 << 2
    
    //Initial game scene set up
    override func didMove(to view: SKView) {
        
        //Sets up physics world
        physicsWorld.contactDelegate = self
        
        //Creates the play button
        playButton = SKSpriteNode(imageNamed: "PlayButton")
        playButton.position = CGPoint(x: frame.midX, y: frame.midY)
        playButton.zPosition = 4.0
        playButton.size.height = 70
        playButton.size.width = 140
        
        addChild(playButton)
    }
    
    //Set screen safe zone
    private var playableRect: CGRect {
        // Define your custom boundaries for x and y
        let minX: CGFloat = -400
        let maxX: CGFloat = -400
        let minY: CGFloat = 0
        let maxY: CGFloat = -550
        
        // Calculate the width and height based on the custom boundaries
        let width = maxX - minX
        let height = maxY - minY
        
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    //Function to play background music
    func playBackgroundMusic() {
        if let path = Bundle.main.path(forResource: "TimeLapse", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            
            do {
                // Create the audio player
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                
                // Set the audio to loop infinitely
                backgroundMusicPlayer?.numberOfLoops = -1
                
                // Play the background music
                backgroundMusicPlayer?.play()
            }
            
            catch {
                print("Error playing background music: \(error.localizedDescription)")
            }
        }
    }
    
    //Function to create scrolling background
    func createBackground() {
        let backgroundTexture = SKTexture(imageNamed: "BG")
        let moveBackground = SKAction.move(by: CGVector(dx: -backgroundTexture.size().width, dy: 0), duration: 5)
        let shiftBackground = SKAction.move(by: CGVector(dx: backgroundTexture.size().width, dy: 0), duration: 0)
        let moveBackgroundForever = SKAction.repeatForever(SKAction.sequence([moveBackground, shiftBackground]))
        
        for i in 0..<2{
            let background = SKSpriteNode(texture: backgroundTexture)
            background.anchorPoint = CGPoint(x:0.5, y: 0.6)
            background.position = CGPoint(x: backgroundTexture.size().width * CGFloat(i), y: frame.midY)
            background.size.height = 720
            background.run(moveBackgroundForever)
            addChild(background)
        }
    }
    
    //Function to create player catstronaut sprite
    func createPlayerSprite() {
        player = SKSpriteNode(imageNamed: "Catstronaut")
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        self.player.zPosition = 2.0
        player.size.height = 70
        player.size.width = 70
        
        addChild(player)
    }
    
    //Function to create enemey space fish sprite
    func createEnemySprite() {
        enemy = SKSpriteNode(imageNamed: "SpaceFish")
        enemy.position = CGPoint(x: frame.maxX + enemy.size.width / 2, y: frame.midY)
        enemy.zPosition = 1.0
        enemy.size.height = 70
        enemy.size.width = 70
        
        //Set up physics body for the space fish
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
        enemy.physicsBody?.categoryBitMask = 0x1
        enemy.physicsBody?.collisionBitMask = 0x2 | 0x1
        enemy.physicsBody?.contactTestBitMask = 0x0
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.allowsRotation = false
        enemy.physicsBody?.restitution = 0.5
        enemy.physicsBody?.linearDamping = 0.1
        enemy.physicsBody?.velocity = CGVector(dx: -200, dy: 0)
        
        addChild(enemy)
        
        //Set up border body
        let borderBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        self.physicsBody = borderBody
        self.physicsBody?.categoryBitMask = obstacleCategory
        self.physicsBody?.collisionBitMask = playerCategory
        self.physicsBody?.contactTestBitMask = 0x0
        
        //Add the scene as the contact delegate
        self.physicsWorld.contactDelegate = self
    }
    
    //Function to create player score label
    func createPlayerScore() {
        scoreLabel = SKLabelNode(text: "SCORE: 0")
        scoreLabel.position = CGPoint(x: frame.minX + 100, y: frame.maxY - 550)
        scoreLabel.zPosition = 3.0
        scoreLabel.fontName = "Helvetica-Bold"
        scoreLabel.fontColor = .white
        scoreLabel.fontSize = 20
        
        addChild(scoreLabel)
    }
    
    //Function to initial detect touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        if gameStarted {
            //Handles player movement touch
            if player.contains(touchLocation) {
                isMovingPlayer = true
            }
        }
        
        else {
            //Handles play button touch
            if playButton.contains(touchLocation) {
                
                //Starts the game
                playBackgroundMusic()
                createBackground()
                createPlayerSprite()
                createEnemySprite()
                createPlayerScore()
                playGame()
                
                //Hides the play button
                playButton.isHidden = true
            }
        }
    }
    
    //Function to have catstronaut follow player touch
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        movePlayer(to: touchLocation)
    }
    
    //Function for when player screen touch ends
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMovingPlayer = false
    }
    
    //Function to move catstronaut sprite
    func movePlayer(to position: CGPoint) {
        let moveAction = SKAction.move(to: position, duration: 0.1)
        player.run(moveAction)
    }
    
    //Obstacle spawning function
    func spawnObstacle() {
        guard gameStarted else { return }
        
        //Create obstacle
        let obstacle = enemy.copy() as! SKSpriteNode
        obstacle.position = CGPoint(x: frame.maxX - obstacle.size.width, y: frame.midY)
        addChild(obstacle)
        
        //Apply an initial impulse to the obstacle to move it
        let initialImpulse = CGVector(dx: -300, dy: 100)
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: obstacle.size.width / 2)
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.collisionBitMask = playerCategory | obstacleCategory
        obstacle.physicsBody?.contactTestBitMask = 0x0
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.allowsRotation = false
        obstacle.physicsBody?.restitution = 1.0
        obstacle.physicsBody?.linearDamping = 0
        obstacle.physicsBody?.velocity = initialImpulse
    }
    
    //Main gameplay function
    func playGame() {
        //Ensure the game is not already started
        guard !gameStarted else { return }
        
        // Reset score
        score = 0
        scoreLabel?.text = "SCORE: \(score)"
        addScore()
        
        //Spawn obstacles at regular intervals
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.spawnObstacle()
        }
        //Set game to started
        gameStarted = true
        
        //Start obstacle-related actions
        let waitAction = SKAction.wait(forDuration: 0.5)
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        run(repeatAction, withKey: "spawnObstacles")
        
        //Starts updating the score
        let updateScoreAction = SKAction.run { [weak self] in
            self?.addScore()
        }
        
        let delayAction = SKAction.wait(forDuration: 1.0)
        let scoreSequence = SKAction.sequence([updateScoreAction, delayAction])
        let scoreRepeatAction = SKAction.repeatForever(scoreSequence)
        run(scoreRepeatAction, withKey: "updateScore")
    }
    
    //Function to add to the player score
    func addScore() {
        score += 1
        scoreLabel?.text = "Score: \(score)"
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == playerCategory && contact.bodyB.categoryBitMask == obstacleCategory {
            gameOver()
        }
        
        else if contact.bodyA.categoryBitMask == obstacleCategory && contact.bodyB.categoryBitMask == playerCategory {
            gameOver()
        }
    }
    
    //Function to handle game over
    func gameOver() {
        //Stop obstacle spawning and score updating actions
        removeAction(forKey: "spawnObstacles")
        removeAction(forKey: "updateScore")
        
        //Show "Game Over" text, player score, and reset button
    }
}


