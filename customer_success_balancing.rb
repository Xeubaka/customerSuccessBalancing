require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = hash_it(customer_success)
    @customers = sort_by_score(hash_it(customers))
    @away_customer_success = away_customer_success

    @customers_attended = []
    @matches = Hash.new {|h,k| h[k]=[]}
  end
  
  # Returns the ID of the customer success with most customers
  def execute
    match_customers_success(get_available_cs)
    most_matches(@matches)
  end
  
  def hash_it(object)
    hash = {}
    object.each do |i|
      hash[i[:id]] = i[:score]
    end
    hash
  end
  
  def sort_by_score(objects)
    objects.invert.sort.to_h.invert
  end

  def set_available_cs
    @customer_success.reject{ |key, _value| @away_customer_success.include?(key) }
  end

  def get_available_cs
    sort_by_score((@away_customer_success.none? ? @customer_success : set_available_cs))
  end

  def set_available_customers
    @customers.reject{ |key, _value| @customers_attended.include?(key)}
  end

  def get_available_customers
    sort_by_score((@customers_attended.none? ? @customers : set_available_customers))
  end

  def match_customers_success(available_cs)
    available_cs.each{ |cs_id, cs_score| match_awaiting_customer(cs_id, cs_score, get_available_customers) }
  end

  def match_awaiting_customer(cs_id, cs_score, customers)
    customers.each do |customer_id, customer_score|
      if customer_score <= cs_score then
        @matches[cs_id] << customer_id
        @customers_attended << customer_id
      end
    end
  end

  def most_matches(matches)
    return 0 if matches.empty?

    most_matchs = matches.map{ |match| match[1].size }.max
    most_matchs_ids = matches.map{ |match| if (match[1].size == most_matchs) then match[0] end }.compact
    (most_matchs_ids.size > 1) ? 0 : most_matchs_ids.first
  end

end


class CustomerSuccessBalancingTests < Minitest::Test
    def test_scenario_one
      balancer = CustomerSuccessBalancing.new(
        build_scores([60, 20, 95, 75]),
        build_scores([90, 20, 70, 40, 60, 10]),
        [2, 4]
      )
      assert_equal 1, balancer.execute
    end

    def test_scenario_two
        balancer = CustomerSuccessBalancing.new(
          build_scores([11, 21, 31, 3, 4, 5]),
          build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
          []
        )
        assert_equal 0, balancer.execute
    end

    def test_scenario_three
        balancer = CustomerSuccessBalancing.new(
          build_scores(Array(1..999)),
          build_scores(Array.new(10000, 998)),
          [999]
        )
        result = Timeout.timeout(1.0) { balancer.execute }
        assert_equal 998, result
    end

    def test_scenario_four
        balancer = CustomerSuccessBalancing.new(
          build_scores([1, 2, 3, 4, 5, 6]),
          build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
          []
        )
        assert_equal 0, balancer.execute
    end

    def test_scenario_five
        balancer = CustomerSuccessBalancing.new(
          build_scores([100, 2, 3, 6, 4, 5]),
          build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
          []
        )
        assert_equal 1, balancer.execute
    end

    def test_scenario_six
        balancer = CustomerSuccessBalancing.new(
          build_scores([100, 99, 88, 3, 4, 5]),
          build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
          [1, 3, 2]
        )
        assert_equal 0, balancer.execute
    end

    def test_scenario_seven
        balancer = CustomerSuccessBalancing.new(
          build_scores([100, 99, 88, 3, 4, 5]),
          build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
          [4, 5, 6]
        )
        assert_equal 3, balancer.execute
    end

    private

    def build_scores(scores)
        scores.map.with_index do |score, index|
        { id: index + 1, score: score }
        end
    end
end
