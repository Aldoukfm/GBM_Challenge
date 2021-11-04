
import UIKit
import Combine
import Charts

public class ChartCell: UICollectionViewCell, ReuseIdentifiableView {
    
    private(set) public var lineChartView: LineChartView! = {
        let chart = LineChartView()
        chart.rightAxis.enabled = false
        chart.leftAxis.enabled = false
        chart.xAxis.enabled = false
        chart.minOffset = 0
        chart.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 20)
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        setupLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupLayout() {
        contentView.addSubview(lineChartView)
        lineChartView.constraintTo(contentView, insets: UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0))
        
    }
    
    func bind(viewModel: ChartViewModel) {
        var dataSets: [ChartDataSetProtocol] = []
        
        let values = viewModel.values.map({
            ChartDataEntry(x: $0.x, y: $0.y)
        })
        
        let dataSet = LineChartDataSet.init(entries: values)
        dataSet.lineWidth = 3
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(Colors.black)
        
        dataSets.append(dataSet)
        
        if let firstValue = viewModel.values.first, let lastValue = viewModel.values.last {
            
            let firstEntry = ChartDataEntry(x: firstValue.x, y: lastValue.y)
            let lastEntry = ChartDataEntry(x: lastValue.x, y: lastValue.y)
            
            let lastValueSet = LineChartDataSet(entries: [firstEntry, lastEntry])
            lastValueSet.drawValuesEnabled = false
            lastValueSet.lineWidth = 2
            lastValueSet.lineDashLengths = [15]
            lastValueSet.drawCirclesEnabled = false
            lastValueSet.setColor(UIColor.systemGray3)
            
            dataSets.append(lastValueSet)
        }

        let data = LineChartData(dataSets: dataSets)
        lineChartView.data = data
    }
}
