import UIKit

struct CellModel {
    var color = UIColor.yellow
}

class Cell: UICollectionViewListCell {
    deinit {
        print("farewell from cell", self)
    }
}

class MyViewController: UIViewController {
    @IBOutlet var collectionView : UICollectionView!

    var dataSource: UICollectionViewDiffableDataSource<Int, Int>!

    var dataModel: [CellModel] = (0...30).map {_ in CellModel() }

    override func viewDidLoad() {
        super.viewDidLoad()

        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        collectionView.collectionViewLayout = layout

        let registration = UICollectionView.CellRegistration<Cell, Int> { [weak self] cell, path, identifier in
            guard let self else { return }

            var config = cell.defaultContentConfiguration()
            config.text = "Howdy \(identifier)"
            cell.contentConfiguration = config
            cell.backgroundConfiguration?.backgroundColor = dataModel[path.item].color
        }

        dataSource = .init(collectionView: collectionView) { collectionView, path, identifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: path, item: identifier)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems((0..<dataModel.count).map { $0 })
        Task {
            await dataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    @IBAction func doButton (_ sender: Any) {
        // Hey, I don't care, I just want a cell I can see
        guard let path = collectionView.indexPathsForVisibleItems.first else { return }
        print("starting")
        Task {
            view.isUserInteractionEnabled = false
            await changeColorUsingReload(path)
            view.isUserInteractionEnabled = true
            print("done")
        }
    }

    func changeColorUsingReload(_ path: IndexPath) async {
        dataModel[path.item].color = .green

        // Proving that `reloadItems` creates a new cell in this slot

        var snapshot = dataSource.snapshot()
        snapshot.reloadItems([path.item])
        let cellBefore = collectionView.cellForItem(at: path)

        await dataSource.apply(snapshot)

        try? await Task.sleep(for: .seconds(1))

        let cellAfter = collectionView.cellForItem(at: path)
        report(#function, cellBefore, cellAfter)

        await changeColorUsingReconfigure(path)
    }

    func changeColorUsingReconfigure(_ path: IndexPath) async {
        self.dataModel[path.item].color = .red

        // Proving that `reconfigureItems` does _not_ create a new cell in this slot

        var snapshot = self.dataSource.snapshot()
        snapshot.reconfigureItems([path.item])
        let cellBefore = collectionView.cellForItem(at: path)

        await dataSource.apply(snapshot)

        try? await Task.sleep(for: .seconds(1))

        let cellAfter = collectionView.cellForItem(at: path)
        report(#function, cellBefore, cellAfter)
    }

    func report(_ function: String, _ cell1: UICollectionViewCell?, _ cell2: UICollectionViewCell?) {
        print(function + " Cells are the same cell? \(cell1! === cell2!)")
    }
}
