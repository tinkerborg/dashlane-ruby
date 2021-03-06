# Copyright (C) 2016 Dmitry Yakimenko (detunized@gmail.com).
# Licensed under the terms of the MIT license. See LICENCE for details.

module Dashlane
    # Base class for all errors, should not be raised
    class Error < StandardError; end

    #
    # Generic errors
    #

    # Something went wrong with the network
    class NetworkError < Error; end

    # Server responded with something we don't understand
    class InvalidResponseError < Error; end

    # Either username or password is invalid, maybe both
    class AuthenticationError < Error; end

    # Server responded with an error that we don't know
    class UnknownError < Error; end

    # An error happened during one of the import operations
    class ImportError < Error; end

    # An error happened during the new device/uki registration
    class RegisterError < Error; end
end
